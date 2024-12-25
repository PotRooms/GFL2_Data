require("UI.Common.UICommonItem")
require("UI.UIBasePanel")
UIDarkZoneDefeatDialog = class("UIDarkZoneDefeatDialog", UIBasePanel)
UIDarkZoneDefeatDialog.__index = UIDarkZoneDefeatDialog

function UIDarkZoneDefeatDialog:ctor(csPanel)
  UIDarkZoneDefeatDialog.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIDarkZoneDefeatDialog:OnInit(root, data)
  UIDarkZoneDefeatDialog.super.SetRoot(UIDarkZoneDefeatDialog, root)
  self:InitBaseData()
  self.mData = data
  self.mReason = data.Reason
  self.mBagDrop = data.BagDrop
  self.mItemTable = {}
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
  self:UpdateData()
  MessageSys:SendMessage(CS.GF2.Message.DarkMsg.DarkZoneHideMainPanel, nil)
  MessageSys:SendMessage(CS.GF2.Message.DarkMsg.DzFinish, false)
end

function UIDarkZoneDefeatDialog:OnShowFinish()
end

function UIDarkZoneDefeatDialog:CloseFunction()
  CS.SysMgr.dzUIControlMgr:DarkEnd()
end

function UIDarkZoneDefeatDialog:OnClose()
  for _, item in pairs(self.mItemTable) do
    gfdestroy(item:GetRoot())
  end
  self.ui = nil
  self.clickTime = nil
  self.canClose = false
end

function UIDarkZoneDefeatDialog:InitBaseData()
  self.clickTime = 1
  self.canClose = false
  TimerSys:DelayCall(2, function()
    self.canClose = true
  end)
end

function UIDarkZoneDefeatDialog:OnRelease()
  self.super.OnRelease(self)
  self.hasCache = false
end

function UIDarkZoneDefeatDialog:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.gameObject).onClick = function()
    if self.canClose then
      self:CloseFunction()
    end
  end
end

function UIDarkZoneDefeatDialog:UpdateData()
  local reasonStr = ""
  local flag = LuaUtils.EnumToInt(self.mReason)
  if flag == 0 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(240046)
  elseif flag == 1 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(903383)
  elseif flag == 2 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(903381)
  elseif flag == 3 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(903382)
  elseif flag == 4 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(240047)
  elseif flag == 5 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(240065)
  elseif flag == 10 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(903602)
  elseif flag == 11 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(903611)
  elseif flag == 12 then
    reasonStr = TableData.GetHintById(903380) .. " " .. TableData.GetHintById(903612)
  else
    gfwarning("\230\156\170\231\159\165\231\154\132\229\164\177\232\180\165\229\142\159\229\155\160")
  end
  self.ui.mText_FailReason.text = reasonStr
  self.ui.mText_Name.text = AccountNetCmdHandler:GetName()
  MessageSys:SendMessage(GuideEvent.OnDarkLose, CS.SysMgr.dzMatchGameMgr.darkZoneType)
  self.mAllBagGoods = {}
  local allBagGoodsDict = self.mBagDrop
  for i = 0, allBagGoodsDict.Count - 1 do
    table.insert(self.mAllBagGoods, allBagGoodsDict[i])
  end
  UIUtils.SortItemTable(self.mAllBagGoods)
  self:ShowBagReward(self.mAllBagGoods)
  setactive(self.ui.mTrans_ItemRoot, self.ui.mSListChild_Content.transform.childCount ~= 0)
  setactive(self.ui.mTrans_None, self.ui.mSListChild_Content.transform.childCount == 0)
end

function UIDarkZoneDefeatDialog:ShowBagReward(allBagGoods)
  if #allBagGoods == 0 then
    return
  end
  for i = 1, #allBagGoods do
    local itemShow = CS.DzGoodsHelper.ShowInSettleById(allBagGoods[i].ItemId)
    if itemShow then
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mSListChild_Content.transform)
      self:SetItem(allBagGoods[i], item)
      table.insert(self.mItemTable, item)
    end
  end
end

function UIDarkZoneDefeatDialog:SetItem(data, item)
  local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(data.ItemId, true)
  if escort_goodData then
    if data.ItemNum <= 1 then
      local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, 0)
      item:SetFakeItem(fakeItemData)
    else
      local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, data.ItemNum)
      item:SetFakeItem(fakeItemData)
    end
  else
    local partData = NetCmdWeaponPartsData:GetWeaponModById(data.Relate)
    if partData ~= nil then
      local OnItemClickedBack = function()
        TipsManager.Add(item.ui.mBtn_Select.gameObject, TableData.GetItemData(data.ItemId), nil, nil, nil, data.Relate)
      end
      item:SetWeaponPartsData(partData, OnItemClickedBack)
      OnItemClickedBack()
    elseif data.ItemNum <= 1 then
      item:SetItemData(data.ItemId, 0, false, false, nil, data.Relate)
    else
      item:SetItemData(data.ItemId, data.ItemNum, false, false, nil, data.Relate)
    end
  end
end
