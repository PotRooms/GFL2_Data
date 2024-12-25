ClearSysData = {}

function ClearSysData.Clear()
  if UIChapterGlobal then
    UIChapterGlobal:RecordChapterId(nil)
  end
  NetCmdDungeonData.HasNewChapterUnlocked = false
  NetCmdDungeonData.NewChapterID = -1
  DarkNetCmdStoreData.questCacheGroupId = 0
  if UIChapterGlobal then
    UIChapterGlobal.OnSaveTabId = nil
  end
  if ActivityCafeGlobal then
    ActivityCafeGlobal.cacheState = 0
    ActivityCafeGlobal.isOnSave = false
  end
  if DormGlobal then
    DormGlobal.IsShowUI = true
  end
end
