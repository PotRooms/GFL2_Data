NewTaskRewardItem = class("NewTaskRewardItem", UIBaseCtrl)

function NewTaskRewardItem:ctor(prefab, parent)
  self.ui = {}
  self:LuaUIBindTable(prefab, self.ui)
  self:SetRoot(prefab.transform)
  self.itemTable = {}
  self.phaseId = 1
  self.dataMap = {}
  self.dataList = {}
end

function NewTaskRewardItem:SetData(phaseId)
  self.phaseId = phaseId
  self.dataMap = {}
  self.dataList = {}
  self.phaseData = TableData.listGuideQuestPhaseDatas:GetDataById(self.phaseId)
  self.rewards = UIUtils.GetKVSortItemTable(self.phaseData.reward_list)
  local questRewardList = TableData.listGuideQuestByPhaseDatas:GetDataById(phaseId)
  for i = 0, questRewardList.Id.Count - 1 do
    local quest = TableData.listGuideQuestDatas:GetDataById(questRewardList.Id[i])
    for id, num in pairs(quest.reward_list) do
      local t = {}
      t.id = id
      t.num = num
      table.insert(self.rewards, t)
    end
  end
  for i = 1, #self.rewards do
    local data = self.rewards[i]
    if self.dataMap[data.id] then
      self.dataMap[data.id].num = self.dataMap[data.id].num + data.num
    else
      self.dataMap[data.id] = data
      data.stcData = TableData.listItemDatas:GetDataById(data.id)
      data.itemTypeData = TableData.listItemTypeDescDatas:GetDataById(data.stcData.type)
    end
  end
  for id, data in pairs(self.dataMap) do
    table.insert(self.dataList, data)
  end
  table.sort(self.dataList, function(a, b)
    if a.itemTypeData.rank ~= b.itemTypeData.rank then
      return a.itemTypeData.rank > b.itemTypeData.rank
    elseif a.stcData.type ~= b.stcData.type then
      return a.stcData.type > b.stcData.type
    elseif a.stcData.rank ~= b.stcData.rank then
      return a.stcData.rank < b.stcData.rank
    else
      return a.id > b.id
    end
  end)
  local specialItem, specialItemIndex
  for i = 1, #self.dataList do
    if self.dataList[i].id == 1015 then
      specialItem = self.dataList[i]
      specialItemIndex = i
      break
    end
  end
  if specialItem then
    table.remove(self.dataList, specialItemIndex)
    table.insert(self.dataList, specialItem)
  end
  self.ui.mText_Name.text = string_format(TableData.GetHintById(112048), tostring(phaseId))
  self:UpdateItem()
end

function NewTaskRewardItem:UpdateItem()
  local j = 1
  local curFinish = NetCmdQuestData:CheckNewbiePhaseIsReceived(self.phaseId)
  for i = #self.dataList, 1, -1 do
    local item = self.itemTable[j]
    j = j + 1
    if item == nil then
      item = UICommonItem.New()
      item:InitCtrl(self.ui.mScrollListChild_Content.transform)
      table.insert(self.itemTable, item)
    end
    item:SetItemData(self.dataList[i].id, self.dataList[i].num)
    item:SetReceivedIcon(curFinish)
    item:SetRewardEffect(self.dataList[i].id == 1015)
  end
  setactive(self.ui.mTrans_Complete, curFinish)
end

function NewTaskRewardItem:OnRelease()
  gfdestroy(self:GetRoot())
  self.rewards = nil
  self.dataMap = {}
  self.dataList = {}
  if self.itemTable then
    self:ReleaseCtrlTable(self.itemTable, true)
  end
end
