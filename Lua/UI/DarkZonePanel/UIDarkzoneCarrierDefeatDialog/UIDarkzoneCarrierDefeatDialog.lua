require("UI.Common.UICommonItem")
require("UI.UIBasePanel")
UIDarkzoneCarrierDefeatDialog = class("UIDarkzoneCarrierDefeatDialog", UIBasePanel)
UIDarkzoneCarrierDefeatDialog.__index = UIDarkzoneCarrierDefeatDialog

function UIDarkzoneCarrierDefeatDialog:ctor(csPanel)
  UIDarkzoneCarrierDefeatDialog.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIDarkzoneCarrierDefeatDialog:OnInit(root, data)
  UIDarkzoneCarrierDefeatDialog.super.SetRoot(UIDarkzoneCarrierDefeatDialog, root)
  self:InitBaseData()
  self.mItemTable = {}
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
  self:UpdateData()
end

function UIDarkzoneCarrierDefeatDialog:OnShowFinish()
end

function UIDarkzoneCarrierDefeatDialog:OnClose()
  for _, item in pairs(self.mItemTable) do
    gfdestroy(item:GetRoot())
  end
  self.ui = nil
  self.clickTime = nil
  self.canClose = false
end

function UIDarkzoneCarrierDefeatDialog:InitBaseData()
  self.clickTime = 1
  self.canClose = false
  TimerSys:DelayCall(2, function()
    self.canClose = true
  end)
end

function UIDarkzoneCarrierDefeatDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIDarkzoneCarrierDefeatDialog:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.gameObject).onClick = function()
    if self.canClose then
      CS.SysMgr.dzMatchGameMgr:StartDarkCarReviveMatch()
    end
  end
end

function UIDarkzoneCarrierDefeatDialog:UpdateData()
  local lostGoodsList = CS.LuaPlayerDataHandler.DarkPlayerBag:GetLostGoodsList()
  self.mLostGoods = {}
  for i = 0, lostGoodsList.Count - 1 do
    table.insert(self.mLostGoods, lostGoodsList[i])
  end
  table.sort(self.mLostGoods, function(a, b)
    local data1 = TableData.GetItemData(a.itemID)
    local data2 = TableData.GetItemData(b.itemID)
    if data1.rank == data2.rank then
      return a.itemID > b.itemID
    else
      return data1.rank > data2.rank
    end
  end)
  for i = 1, #self.mLostGoods do
    local itemShow = self.mLostGoods[i]:ShowInSettle()
    if itemShow then
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mSListChild_Content.transform)
      local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(self.mLostGoods[i].itemID)
      if escort_goodData then
        if 1 >= self.mLostGoods[i].num then
          local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, 0)
          item:SetFakeItem(fakeItemData)
        else
          local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, self.mLostGoods[i].num)
          item:SetFakeItem(fakeItemData)
        end
      elseif 1 >= self.mLostGoods[i].num then
        item:SetItemData(self.mLostGoods[i].itemID, 0, false, false, nil, self.mLostGoods[i].onlyID)
      else
        item:SetItemData(self.mLostGoods[i].itemID, self.mLostGoods[i].num, false, false, nil, self.mLostGoods[i].onlyID)
      end
      table.insert(self.mItemTable, item)
    end
  end
  self.ui.mText_Hint.text = TableData.GetHintById(271058)
  local childCount = self.ui.mSListChild_Content.transform.childCount
  setactive(self.ui.mTrans_ItemRoot, childCount ~= 0)
  setactive(self.ui.mTrans_None, childCount == 0)
  if childCount == 0 then
    self.ui.mText_Hint.text = TableData.GetHintById(271308)
  end
end
