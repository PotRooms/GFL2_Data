require("UI.UIBasePanel")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.Command.Btn_ActivityTourEventSelectItem")
ActivityTourEventSelectDialog = class("ActivityTourEventSelectDialog", UIBasePanel)
ActivityTourEventSelectDialog.__index = ActivityTourEventSelectDialog

function ActivityTourEventSelectDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function ActivityTourEventSelectDialog:OnAwake(root, data)
end

function ActivityTourEventSelectDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
  self.listItem = {}
  self:AddBtnListener()
  self.selectIdList = {}
  self.rewardData = nil
  self.mDialogType = data.dialogType
  self.successCallBack = data.successCallBack
  self.title = data.title
  self.listReward = data.rewards
  self.maxCanSelectNum = data.pickNum
  local rewardNum = self.listReward.Count
  if rewardNum == 0 then
    print_error("\230\178\161\230\156\137\230\148\182\229\136\176RewardList\229\141\143\232\174\174")
    return
  end
  if self.maxCanSelectNum == nil then
    self.maxCanSelectNum = 1
  end
  if rewardNum < self.maxCanSelectNum then
    self.maxCanSelectNum = rewardNum
  end
  setactive(self.ui.mBtn_Select.gameObject, false)
end

function ActivityTourEventSelectDialog:RefreshBaseInfo()
  if self.title then
    self.ui.mText_Title.text = self.title
  else
    print_error("\230\160\135\233\162\152\229\188\130\229\184\184")
  end
  self:RefreshSelectInfo()
end

function ActivityTourEventSelectDialog:OnShowStart()
  self:RefreshBaseInfo()
  self:RefreshList()
end

function ActivityTourEventSelectDialog:RefreshSelectInfo()
  self.ui.mText_Tips.text = UIUtils.StringFormat(MonopolyUtil:GetMonopolyActivityHint(270284), #self.selectIdList, self.maxCanSelectNum)
end

function ActivityTourEventSelectDialog:OnClose()
  self:CloseCallBack()
  self:ReleaseCtrlTable(self.listItem, true)
  self.listItem = {}
end

function ActivityTourEventSelectDialog:OnRelease()
  self.ui = nil
  self.listReward = nil
end

function ActivityTourEventSelectDialog:RefreshList()
  for i = 1, self.listReward.Count do
    local item = self.listItem[i]
    if not item then
      item = Btn_ActivityTourEventSelectItem.New()
      item:InitCtrl(self.ui.mScrollListChild_Content.childItem, self.ui.mScrollListChild_Content.transform)
      self.listItem[i] = item
    end
    setactive(item.mUIRoot, true)
    item:SetSelectCallBack(i, self.RefreshSelect)
    self:RefreshItem(item, i - 1)
  end
  for i = self.listReward.Count + 1, #self.listItem do
    setactive(self.listItem[i].mUIRoot, false)
  end
end

function ActivityTourEventSelectDialog.RefreshSelect(selIdx)
  self = ActivityTourEventSelectDialog
  self.selectIdList = {selIdx}
  for i = 1, self.listReward.Count do
    local item = self.listItem[i]
    if item then
      self.selIdx = selIdx
      item:RefreshSelect(selIdx)
      self:SelectItem()
    end
  end
  setactive(self.ui.mBtn_Select.gameObject, #self.selectIdList >= self.maxCanSelectNum)
  self:RefreshSelectInfo()
end

function ActivityTourEventSelectDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Select.gameObject).onClick = function()
    self:OnBtnSelect()
  end
end

function ActivityTourEventSelectDialog:ResetListReward()
  self.listReward:Clear()
  self.listReward = nil
  self.successCallBack = nil
  self.ret = nil
  self.rewardData = nil
end

function ActivityTourEventSelectDialog:OnBtnSelect()
  self.rewardData = {}
  for i = 1, #self.selectIdList do
    local selectIndex = self.selectIdList[i]
    local rewardData = self.listReward[selectIndex - 1]
    if rewardData then
      table.insert(self.rewardData, rewardData)
    end
  end
  UIManager.CloseUI(UIDef.ActivityTourEventSelectDialog)
end

function ActivityTourEventSelectDialog:CloseCallBack()
  if self.rewardData ~= nil and self.successCallBack then
    self.successCallBack(self.rewardData)
  end
  self.successCallBack = nil
  self:ResetListReward()
end

function ActivityTourEventSelectDialog:RefreshItem(itemCtrl, index)
  self:RefreshRandomPointItem(itemCtrl, index)
end

function ActivityTourEventSelectDialog:SelectItem()
  self:SelectRandomReward()
end

function ActivityTourEventSelectDialog:RefreshFuncPoint()
end

function ActivityTourEventSelectDialog:RefreshRandomPointItem(itemCtrl, index)
  if not self.listReward or self.listReward.Count <= 0 then
    print_error("ActivityTourEventSelectDialog:\233\154\143\230\156\186\228\186\139\228\187\182\229\165\150\229\138\177\228\184\186\231\169\186!")
    return
  end
  if itemCtrl == nil then
    print_error("ActivityTourEventSelectDialog:itemCtrl is null!")
    return
  end
  if self.listReward[index].Type == ActivityTourGlobal.RandomRewardType.Points then
    itemCtrl:SetPointData(self.listReward[index].Num)
  elseif self.listReward[index].Type == ActivityTourGlobal.RandomRewardType.Item then
    itemCtrl:SetInspirationData(self.listReward[index].Id, self.listReward[index].Num)
  elseif self.listReward[index].Type == ActivityTourGlobal.RandomRewardType.Buff then
    itemCtrl:SetBuffData(self.listReward[index].Id)
  else
    itemCtrl:SetCommandData(self.listReward[index].Id)
  end
end

function ActivityTourEventSelectDialog:SelectRandomReward()
end
