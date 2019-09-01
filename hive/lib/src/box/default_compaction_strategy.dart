const _deletedRatio = 0.15;
const _deletedThreshold = 60;

bool defaultCompactionStrategy(int entries, int deletedEntries) {
  return deletedEntries > _deletedThreshold &&
      deletedEntries / entries > _deletedRatio;
}
