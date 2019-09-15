import 'dart:math';

class IndexableSkipList<K, V> {
  static const maxHeight = 8;

  final Node<K, V> head = Node(null, null, List(maxHeight), List(maxHeight));

  final Random random = Random();

  final Comparator<K> comparator;

  int _height = 1;

  int _length;

  IndexableSkipList(this.comparator);

  void set(K key, V value) {
    // calculate this new node's level
    var level = 1;
    while (random.nextBool() && level < maxHeight) {
      level++;
    }

    var node = Node<K, V>(key, value, List(level), List(level));

    var current = head;
    // Next & Down
    for (var i = _height; i >= 0; i--) {
      while (true) {
        var next = current.next[i];
        if (next == null || comparator(key, next.key) < 0) break;
        current = next;
      }

      // CHANGE 1 - Increase all the above node's width by 1
      if (i > level) {
        var next = node.next[i];
        if (next != null) {
          next.width[i]++;
        }
        continue;
      }

      if (i == 0) {
        // CHANGE 2 - Nodes at level 0 always have a width of 1
        node.width[0] = 1;
      } else {
        // CHANGE 3 - Calculate the level of the node
        var width = 0;
        var node = current.next[i - 1];
        while ((node = node.next[i - 1]) != null) {
          if (comparator(key, node.key) < 0) {
            break;
          }
          width += node.width[i - 1];
        }
        for (var j = i; j <= level; j++) {
          node.width[j] += width;
        }
        node.width[i] += 1;
      }
      node.next[i] = current.next[i];
      current.next[i] = node;
      node.prev = current;
    }

    // CHANGE 4 - Adjust the width of all next nodes
    for (var i = 1; i <= level; i++) {
      var next = node.next[i];
      if (next != null) {
        next.width[i] -= node.width[i] - 1;
      }
    }
  }

/*func (s *Skiplist) Skip(offset int) *SkiplistNode {
  // -1 since we're 0 based and skipping 0 means
  // we we want the 1st item which has a width of 1
  skipped := -1
  current := s.head
  for i := s.height; i >= 0; i-- {
    next := current.next[i]
    if next == nil { continue }
    width := next.width[i]
    if skipped + width > offset { continue }
    current = next

    for ; current != nil; current = current.next[i] {
      skipped += current.width[i]
      if skipped == offset { return current }
      next := current.next[i]
      if next == nil || next.width[i] + skipped > offset {
        break
      }
    }
  }
  return nil
}*/

  void draw() {
    print("\n");

    for (var level = maxHeight; level >= 0; level--) {
      if (head.next[level] == null) {
        continue;
      }
      print(level.toString() + ": ");
      for (var node = head.next[level]; node != null; node = node.next[level]) {
        var width = node.width[level];
        print("--" +
            "------" * width +
            node.value.toString() +
            "(" +
            width.toString() +
            ")");
      }
      print("");
    }
    print('');
  }
}

class Node<K, V> {
  final K key;

  V value;

  final List<Node<K, V>> next;

  Node<K, V> prev;

  final List<int> width;

  Node(this.key, this.value, this.next, this.width);
}

void findFirstBit() {
  var n = 4;
  print(log(n & -n) / log(2) + 1);
}
