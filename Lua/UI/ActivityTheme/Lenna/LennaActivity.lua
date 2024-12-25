LennaActivity = {}
LennaActivity.bingoConfig = {
  width = 4,
  height = 4,
  startX = 2,
  startY = 2,
  rewardWidth = 4,
  rewardHeight = 4,
  totalWidth = 6
}

function LennaActivity.Enter(tab, activityConfigData)
  local playAvg = activityConfigData.prologue > 0 and NetCmdThemeData:GetThemeAVGState(activityConfigData.id) < 1
  if tab.activityModuleData.stage_type == 1 then
    NetCmdActivityBingoData:GetBingoInfo(tab.activityEntranceData.id, function(ret)
      if ret == ErrorCodeSuc then
        UIManager.OpenUIByParam(UIDef.LennaPreWarmPanel, {
          activityEntranceData = tab:GetActivityEntranceData(),
          activityModuleData = tab:GetActivityModuleData(),
          activityConfigData = tab:GetActivityConfigData()
        })
        if playAvg then
          CS.AVGController.PlayAvgByPlotId(activityConfigData.prologue, function()
            NetCmdThemeData:SetThemeAVGState(activityConfigData.id, 1)
          end, true)
        end
      end
    end)
  else
    UIManager.OpenUIByParam(UIDef.LennaMainPanel, {
      activityEntranceData = tab:GetActivityEntranceData(),
      activityModuleData = tab:GetActivityModuleData(),
      activityConfigData = tab:GetActivityConfigData()
    })
  end
end
