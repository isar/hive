import 'big_int_adapter_test.dart' as big_int_adapter_test;
import 'binary_reader_test.dart' as binary_reader_test;
import 'binary_writer_buffer_test.dart' as binary_writer_buffer_test;
import 'binary_writer_test.dart' as binary_writer_test;
import 'box_base_test.dart' as box_base_test;
import 'box_impl_test.dart' as box_impl_test;
import 'buffered_file_reader_test.dart' as buffered_file_reader_test;
import 'change_notifier_test.dart' as change_notifier_test;
import 'crc32_test.dart' as crc32_test;
import 'date_time_adapter_test.dart' as date_time_adapter_test;
import 'default_compaction_strategy_test.dart'
    as default_compaction_strategy_test;
import 'frame_io_helper_test.dart' as frame_io_helper_test;
import 'frame_test.dart' as frame_test;
import 'hive_impl_test.dart' as hive_impl_test;
import 'keystore_test.dart' as keystore_test;
import 'lazy_box_impl_test.dart' as lazy_box_impl_test;
import 'lock_test.dart' as lock_test;
import 'other_test.dart' as other_test;
import 'storage_backend_vm_test.dart' as storage_backend_vm_test;
import 'synced_file_test.dart' as synced_file_test;
import 'type_registry_impl_test.dart' as type_registry_impl_test;

void main() {
  big_int_adapter_test.main();
  binary_reader_test.main();
  binary_writer_buffer_test.main();
  binary_writer_test.main();
  box_base_test.main();
  box_impl_test.main();
  buffered_file_reader_test.main();
  change_notifier_test.main();
  crc32_test.main();
  date_time_adapter_test.main();
  default_compaction_strategy_test.main();
  frame_io_helper_test.main();
  frame_test.main();
  hive_impl_test.main();
  keystore_test.main();
  lazy_box_impl_test.main();
  lock_test.main();
  other_test.main();
  storage_backend_vm_test.main();
  synced_file_test.main();
  type_registry_impl_test.main();
}
