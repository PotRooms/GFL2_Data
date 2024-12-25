require("UI.UIBaseCtrl")
require("UI.Common.UICommonItem")
PVPRankRewardItem = class("PVPRankRewardItem", UIBaseCtrl)
PVPRankRewardItem.__index = PVPRankRewardItem

function PVPRankRewardItem:ctor()
end

function PVPRankRewardItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(instObj.transform)
  self.itemUIList = {}
  self.emptyUIList = {}
  self.maxCount = 3
  setactive(self.ui.mTrans_Empty.gameObject, false)
end

function PVPRankRewardItem:SetData(data, rankRate)
  if data.reward_type == 1 then
    if 1 < data.rank_section.Count then
      self.ui.mText_Num.text = data.rank_section[0] .. " - " .. data.rank_section[1] .. TableData.GetHintById(290606)
    end
  elseif 1 < data.rank_section.Count then
    self.ui.mText_Num.text = string_format(TableData.GetHintById(290003), data.rank_section[1])
    setactive(self.ui.mTrans_RewardText.gameObject, rankRate > data.rank_section[0] and rankRate <= data.rank_section[1])
  else
    self.ui.mText_Num.text = string_format(TableData.GetHintById(290003), data.rank_section[0])
  end
  local rewardList = UIUtils.GetKVSortItemTable(data.rank_reward)
  for i = 1, self.maxCount do
    if rewardList[i] then
      local itemview = self.itemUIList[i]
      if itemview == nil then
        itemview = UICommonItem.New()
        itemview:InitCtrl(self.ui.mTrans_Reward)
        itemview.mUIRoot:SetAsLastSibling()
        table.insert(self.itemUIList, itemview)
      end
      itemview:SetItemData(rewardList[i].id, rewardList[i].num)
    end
  end
  local emptyCount = self.maxCount - #rewardList
  for j = 1, emptyCount do
    local empty = self.emptyUIList[j]
    if empty == nil then
      empty = instantiate(self.ui.mTrans_Empty, self.ui.mTrans_Reward)
      empty.transform:SetAsLastSibling()
      table.insert(self.emptyUIList, empty)
    end
    setactive(empty.gameObject, true)
  end
end
