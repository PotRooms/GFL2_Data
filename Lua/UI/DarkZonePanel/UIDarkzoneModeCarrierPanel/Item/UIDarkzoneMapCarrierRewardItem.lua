require("UI.UIBaseCtrl")
require("UI.DarkZonePanel.UIDarkzoneModeCarrierPanel.Item.UIDarkExangeItem")
UIDarkzoneMapCarrierRewardItem = class("UIDarkzoneMapCarrierRewardItem", UIBaseCtrl)
UIDarkzoneMapCarrierRewardItem.__index = UIDarkzoneMapCarrierRewardItem

function UIDarkzoneMapCarrierRewardItem:InitCtrl(prefab, parent, callback)
  local obj = instantiate(prefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self.itemList = {}
  self.exchangeList = {}
  setactive(self.ui.mTrans_Exchange, false)
  setactive(self.ui.mTrans_ExchangeList, false)
  self:SetTop(true)
end

function UIDarkzoneMapCarrierRewardItem:SetRewardData(listData, questID)
  setactive(self.ui.mTrans_Reward, true)
  setactive(self.ui.mTrans_Exchange, false)
  local firstCount = 0
  if questID and not NetCmdActivityDarkZone:CheckQuestFinish(questID) then
    self.questData = TableData.listDzActivityQuestDatas:GetDataById(questID)
    firstCount = self.questData.FirstQuestReward.Count
  end
  for i = 0, listData.Count - 1 do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mScrollListChild_GrpRewardList.transform)
    local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(listData[i], true)
    if escort_goodData then
      local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, 0)
      item:SetFakeItem(fakeItemData)
    else
      item:SetItemData(listData[i], 0, false, false, nil)
    end
    if self.questData and i < firstCount then
      local first = self.questData.first_quest_reward.Keys:Contains(listData[i])
      item:SetFirstDrop(first)
    end
    table.insert(self.itemList, item)
  end
end

function UIDarkzoneMapCarrierRewardItem:SetRewardDataWithNum(listData, questID)
  setactive(self.ui.mTrans_Reward, true)
  setactive(self.ui.mTrans_Exchange, false)
  local firstCount = 0
  self.questData = TableData.listDzActivityQuestDatas:GetDataById(questID)
  if questID and not NetCmdActivityDarkZone:CheckQuestFinish(questID) then
    firstCount = self.questData.FirstQuestReward.Count
  end
  for i = 0, listData.Count - 1 do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mScrollListChild_GrpRewardList.transform)
    local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(listData[i], true)
    if self.questData and i < firstCount then
      local first = self.questData.first_quest_reward.Keys:Contains(listData[i])
      item:SetFirstDrop(first)
      if escort_goodData then
        local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, self.questData.FirstQuestReward[listData[i]])
        item:SetFakeItem(fakeItemData)
      else
        item:SetItemData(listData[i], self.questData.FirstQuestReward[listData[i]], false, false, nil)
      end
    elseif escort_goodData then
      local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, self.questData.QuestReward[listData[i]])
      item:SetFakeItem(fakeItemData)
    else
      item:SetItemData(listData[i], self.questData.QuestReward[listData[i]], false, false, nil)
    end
    table.insert(self.itemList, item)
  end
end

function UIDarkzoneMapCarrierRewardItem:CreateExchangeList(itemIdList)
  setactive(self.ui.mTrans_ExchangeList, true)
  for j = 0, itemIdList.Count - 1 do
    local goodData = TableData.listActivityEscortExchangeDatas:GetDataById(itemIdList[j], true)
    local item = self.exchangeList[j + 1]
    if item == nil then
      item = UIDarkExangeItem.New()
      item:InitCtrl(self.ui.mTrans_Exchange, self.ui.mTrans_ExchangeList)
      table.insert(self.exchangeList, item)
    end
    item:SetExchangeData(goodData)
  end
end

function UIDarkzoneMapCarrierRewardItem:CreateEscortExchangeList(itemIdList, dataList)
  setactive(self.ui.mTrans_ExchangeList, true)
  local index = 1
  local flag = 0
  for j = 0, itemIdList.Count - 1 do
    local item = self.exchangeList[index]
    local escortExchange = self:GetContainEscortExchange(itemIdList[j], dataList)
    if escortExchange then
      flag = 1
      index = index + 1
      if item == nil then
        item = UIDarkExangeItem.New()
        item:InitCtrl(self.ui.mTrans_Exchange, self.ui.mTrans_ExchangeList)
        table.insert(self.exchangeList, item)
      end
      local goodData = TableData.listActivityEscortExchangeDatas:GetDataById(itemIdList[j], true)
      item:SetExchangeData(goodData, escortExchange.num)
    end
  end
  return flag
end

function UIDarkzoneMapCarrierRewardItem:GetContainEscortExchange(id, dataList)
  for i = 0, dataList.Count - 1 do
    if dataList[i].itemId == id then
      return dataList[i]
    end
  end
  return nil
end

function UIDarkzoneMapCarrierRewardItem:SetRaidData(raidData)
  setactive(self.ui.mTrans_Reward, true)
  setactive(self.ui.mTrans_Exchange, false)
  local showData = UIUtils.GetKVSortItemTable(raidData.sweep_reward)
  for index, pair in pairs(showData) do
    local id = pair.id
    local num = pair.num
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mScrollListChild_GrpRewardList.transform)
    local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(id, true)
    if escort_goodData then
      local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, num)
      item:SetFakeItem(fakeItemData)
    else
      item:SetItemData(id, num, false, false, nil)
    end
    table.insert(self.itemList, item)
  end
  local str = raidData.evaluate_level.str .. " (" .. string_format(TableData.GetHintById(271096), raidData.point[0]) .. ")"
  self:SetTopText(str)
  self:SetImg(raidData.evaluate_icon)
end

function UIDarkzoneMapCarrierRewardItem:SetTop(isShow)
  setactive(self.ui.mTrans_Top, isShow)
end

function UIDarkzoneMapCarrierRewardItem:SetTopText(text)
  self.ui.mText_Title.text = text
end

function UIDarkzoneMapCarrierRewardItem:SetImg(img)
  self.ui.mImg_Icon.sprite = IconUtils.GetAtlasIcon(img)
end

function UIDarkzoneMapCarrierRewardItem:OnRelease()
  for i = 1, #self.itemList do
    self.itemList[i]:OnRelease()
  end
  for i = 1, #self.exchangeList do
    self.exchangeList[i]:OnRelease()
  end
  gfdestroy(self:GetRoot())
end

function UIDarkzoneMapCarrierRewardItem:SetShow(isShow)
  setactive(self:GetRoot(), isShow)
end
