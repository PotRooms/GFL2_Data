require("UI.ActivityTreasurePanel.Item.UIActivityTreasureBpMissionItem")
UIActivityTreasureBpMissionSubPanel = class("UIActivityTreasureBpMissionSubPanel", UIBaseView)
UIActivityTreasureBpMissionSubPanel.__index = UIActivityTreasureBpMissionSubPanel

function UIActivityTreasureBpMissionSubPanel:InitCtrl(root)
  self.ui = {}
  self:SetRoot(root)
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Receive.gameObject, function()
    self:ClickReceive()
  end)
  
  function self.ui.mScrollCtrl.itemCreated(renderData)
    self:ItemProvider(renderData)
  end
  
  function self.ui.mScrollCtrl.itemRenderer(index, rendererData)
    self:ItemRenderer(index, rendererData)
  end
end

function UIActivityTreasureBpMissionSubPanel:SetTab(tab)
  self.tab = tab
end

function UIActivityTreasureBpMissionSubPanel:ClickReceive()
  NetCmdActivityTreasureData:SendReceiveAllMissions(function(ret)
    if ret == ErrorCodeSuc then
      NetCmdActivityTreasureData:DirtyRedPoint()
      UISystem:OpenCommonReceivePanel()
      MessageSys:SendMessage(UIEvent.OnTreasureMissionComplete, nil)
    end
  end)
end

function UIActivityTreasureBpMissionSubPanel:ItemProvider(renderData)
  local itemView = UIActivityTreasureBpMissionItem.New()
  itemView:InitCtrlWithNoInstantiate(renderData.gameObject)
  renderData.data = itemView
  table.insert(self.missionItems, itemView)
end

function UIActivityTreasureBpMissionSubPanel:ItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.missionData[index + 1]
  item:SetData(data)
end

function UIActivityTreasureBpMissionSubPanel:OnSingleMissionComplete()
  NetCmdActivityTreasureData:DirtyRedPoint()
  UISystem:OpenCommonReceivePanel()
end

function UIActivityTreasureBpMissionSubPanel:EnableSubPanel(id)
  self.id = id
  self.missionItems = {}
  self.missionData = {}
  self:RefreshUI()
  setactive(self.mUIRoot.gameObject, true)
end

function UIActivityTreasureBpMissionSubPanel:RefreshUI()
  self:SortMission()
  self.ui.mScrollCtrl.numItems = #self.missionData
  local missionComplete = NetCmdActivityTreasureData:HasMissionCanReceive(self.id)
  setactivewithcheck(self.ui.mTrans_Receive.gameObject, missionComplete)
end

function UIActivityTreasureBpMissionSubPanel:SortMission()
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  local missions = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).TaskId
  local tempMissions = {}
  for i = 0, missions.Count - 1 do
    table.insert(tempMissions, missions[i])
  end
  table.sort(tempMissions, function(a, b)
    local stateA = NetCmdActivityTreasureData:GetMissionStatus(a)
    local stateB = NetCmdActivityTreasureData:GetMissionStatus(b)
    if stateA == stateB then
      return a < b
    else
      return stateB == 2 or stateA == 1
    end
  end)
  for _, mission in ipairs(tempMissions) do
    table.insert(self.missionData, mission)
  end
end

function UIActivityTreasureBpMissionSubPanel:ClearMissionItems()
  if self.missionItems == nil then
    return
  end
  for i = #self.missionItems, 1, -1 do
    local item = self.missionItems[i]
    item:OnRelease()
    table.remove(self.missionItems, i)
  end
  self.ui.mScrollCtrl:DestroyAllItem()
  self.missionItems = {}
end

function UIActivityTreasureBpMissionSubPanel:RefreshMissionStatus()
  local hasMission = NetCmdActivityTreasureData:CheckBpMission(self.id) > 0
  self.tab:SetRedPointVisible(hasMission)
  if not self.mUIRoot.gameObject.activeSelf then
    return
  end
  self.missionData = {}
  self:SortMission()
  self.ui.mScrollCtrl:Refresh()
  self.ui.mScrollCtrl:SetLayoutDoneDirty()
  setactivewithcheck(self.ui.mTrans_Receive.gameObject, hasMission)
end

function UIActivityTreasureBpMissionSubPanel:DisableSubPanel()
  self:ClearMissionItems()
  setactive(self.mUIRoot.gameObject, false)
end
