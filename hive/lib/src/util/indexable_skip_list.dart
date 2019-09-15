import 'dart:math';

class IndexableSkipList<K, V> {
  static const maxHeight = 12;

  final Node<K, V> _head = Node(
    null,
    null,
    List(maxHeight),
    List.filled(maxHeight, 0),
  );

  final Random random = Random();

  final Comparator<K> comparator;

  int _height = 1;

  int _length = 0;

  IndexableSkipList(this.comparator);

  int get length => _length;

  void set(K key, V value, bool overrideExisting) {
    if (overrideExisting) {
      var node = _getNode(key);
      if (node != null) {
        node.value = value;
        return;
      }
    }

    // calculate this new node's level
    var newLevel = 0;
    while (random.nextBool() && newLevel < maxHeight) {
      newLevel++;
    }
    if (newLevel > _height) {
      newLevel = ++_height;
    }

    var newNode = Node<K, V>(
      key,
      value,
      List(newLevel + 1),
      List.filled(newLevel + 1, 0),
    );

    var current = _head;
    // Next & Down
    for (var level = _height - 1; level >= 0; level--) {
      while (true) {
        var next = current.next[level];
        if (next == null || comparator(key, next.key) < 0) break;
        current = next;
      }

      // CHANGE 1 - Increase all the above node's width by 1
      if (level > newLevel) {
        var next = current.next[level];
        if (next != null) {
          next.width[level]++;
        }
        continue;
      }

      if (level == 0) {
        // CHANGE 2 - Nodes at level 0 always have a width of 1
        newNode.width[0] = 1;
      } else {
        // CHANGE 3 - Calculate the width of the level
        var width = 0;
        var node = current.next[level - 1];
        while (node != null && comparator(key, node.key) >= 0) {
          width += node.width[level - 1];
          node = node.next[level - 1];
        }

        for (var j = level; j <= newLevel; j++) {
          newNode.width[j] += width;
        }
        newNode.width[level] += 1;
      }

      // Insert new node at the correct position in this level
      newNode.next[level] = current.next[level];
      current.next[level] = newNode;
    }

    // CHANGE 4 - Adjust the width of all next nodes
    for (var i = 1; i <= newLevel; i++) {
      var next = newNode.next[i];
      if (next != null) {
        next.width[i] -= newNode.width[i] - 1;
      }
    }

    _length++;
  }

  V get(K key) => _getNode(key)?.value;

  Node<K, V> _getNode(K key) {
    var prev = _head;
    Node<K, V> next;
    for (var i = _height - 1; i >= 0; i--) {
      next = prev.next[i];

      while (next != null && comparator(key, next.key) > 0) {
        prev = next;
        next = next.next[i];
      }
    }

    if (next != null && comparator(key, next.key) == 0) {
      return next;
    }
    return null;
  }

  V getAt(int index) {
    var skipped = -1;
    var current = _head;
    for (var i = _height - 1; i >= 0; i--) {
      var next = current.next[i];

      if (next == null) {
        // we've reach the end of this level, go down to
        // the next one
        continue;
      }

      var width = next.width[i];
      if (skipped + width > index) {
        // if we were to move forward, we'd end up skipping too much
        // so it's time to go down to the next level
        continue;
      }

      // ok, we know for sure we can move forward and, at least the
      // first node can be "consumed"
      current = next;
      while (true) {
        skipped += current.width[i];

        // we've found our node
        if (skipped == index) {
          return current.value;
        }

        next = current.next[i];
        if (next == null || next.width[i] + skipped > index) {
          // the next element is either nil, or consuming it
          // would skip too much, break and go to the next levle
          break;
        }
      }
    }
    return null;
  }

  void draw() {
    var output = StringBuffer();
    output.writeln();

    for (var level = maxHeight - 1; level >= 0; level--) {
      if (_head.next[level] == null) {
        continue;
      }

      output.write(level.toString() + ": ");
      for (var node = _head.next[level];
          node != null;
          node = node.next[level]) {
        var width = node.width[level];
        output.write("--" +
            "------" * (width - 1) +
            node.key.toString() +
            "(" +
            width.toString() +
            ")");
      }
      output.writeln();
    }
    print(output.toString());
  }
}

class Node<K, V> {
  final K key;

  V value;

  final List<Node<K, V>> next;

  final List<int> width;

  Node(this.key, this.value, this.next, this.width);
}

abstract class _Iterator<K, V, E> implements Iterator<E> {
  Node<K, V> node;

  _Iterator(this.node);

  @override
  bool moveNext() => (node = node.next[0]) != null;
}

class _KeyIterator<K, V> extends _Iterator<K, V, K> {
  _KeyIterator(Node<K, V> node) : super(node);

  @override
  K get current => node.key;
}

//class _KeyIterable<K, V> extends EfficientLengthIterable {}

class _ValueIterator<K, V> extends _Iterator<K, V, V> {
  _ValueIterator(Node<K, V> node) : super(node);

  @override
  V get current => node.value;
}
