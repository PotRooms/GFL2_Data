ActivityCafeGlobal = {}
ActivityCafeGlobal.FormalDialogKey = "_FormalDialogKey_"
ActivityCafeGlobal.SynthesisMachineMap = {
  [170037] = 997,
  [170032] = 998,
  [170027] = 999
}
ActivityCafeGlobal.VisionCache = 0
ActivityCafeGlobal.stateChangeTimer = nil
ActivityCafeGlobal.cacheOpenDarkzone = nil
ActivityCafeGlobal.IsNeedOpenMessageBox = false
ActivityCafeGlobal.LoadFinish = false
ActivityCafeGlobal.cacheState = 0
ActivityCafeGlobal.isOnSave = false
ActivityCafeGlobal.IsReadyStartTutorial = true

function ActivityCafeGlobal.ShowToMainBox()
  MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(272001), nil, function()
    UISystem:JumpToMainPanel()
  end, UIGroupType.Default)
  return
end
