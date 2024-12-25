require("UI.UIBaseCtrl")
HigherPVPRankInvolvedRewardItem = class("HigherPVPRankInvolvedRewardItem", UIBaseCtrl)
HigherPVPRankInvolvedRewardItem.__index = HigherPVPRankInvolvedRewardItem

function HigherPVPRankInvolvedRewardItem:ctor()
end

function HigherPVPRankInvolvedRewardItem:InitCtrl(parent)
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
  UIUtils.GetButtonListener(self.ui.mBtn_Record.gameObject).onClick = function()
    if self.data then
      if CS.UIUtils.GetTouchClicked() then
        return
      end
      CS.UIUtils.SetTouchClicked()
      NetCmdHigherPVPData:MsgCsHighPvpAtkReward(self.data.id, function()
        UISystem:OpenCommonReceivePanel()
      end)
    end
  end
end

function HigherPVPRankInvolvedRewardItem:SetData(data)
  self.data = data
  local totalCount = NetCmdHigherPVPData:GetAtkTotalCount()
  self.ui.mText_Info.text = string_format(TableData.GetHintById(290910), totalCount, data.times)
  local rewardList = UIUtils.GetKVSortItemTable(data.reward)
  local rewardState = NetCmdHigherPVPData:GetAtkStateBytimeData(data)
  setactive(self.ui.mTrans_TextNo.gameObject, rewardState == 0)
  setactive(self.ui.mBtn_Record.gameObject, rewardState == 1)
  setactive(self.ui.mTrans_BtnRecord.gameObject, rewardState == 1)
  setactive(self.ui.mTrans_ImgComplete.gameObject, rewardState == 2)
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
