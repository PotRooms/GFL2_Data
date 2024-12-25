require("UI.UIBasePanel")
require("UI.ActivityTheme.Cafe.Item.UICafeDrinkDetailItem")
UIActivityCafeDrinkDetailsDialog = class("UIActivityCafeDrinkDetailsDialog", UIBasePanel)
UIActivityCafeDrinkDetailsDialog.__index = UIActivityCafeDrinkDetailsDialog

function UIActivityCafeDrinkDetailsDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityCafeDrinkDetailsDialog:OnInit(root, data)
  self.super.SetRoot(UIActivityCafeDrinkDetailsDialog, root)
  self.module_id = 3003
  self.config_id = 101
  self.activity_id = NetCmdActivitySimData.offcialConfigId
  CSUIUtils.GetAndSetActivityHintText(root, self.activity_id, 2, self.module_id, self.config_id)
  self.data = data
  self.machineTablData = TableData.listActivitySimArticleDatas:GetDataById(data.id)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:RegisterEvent()
  self:UpdateInfo()
end

function UIActivityCafeDrinkDetailsDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_BgClose.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self.CloseSelf()
  end
  
  function self.onSimCafeDropTimeout(msg)
    if self.data.id == msg.Sender then
      TimerSys:DelayFrameCall(1, function()
        self:UpdateLeftTime()
      end)
    end
  end
  
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.SimCafeDropTimeout, self.onSimCafeDropTimeout)
end

function UIActivityCafeDrinkDetailsDialog:OnShowFinish()
  self.ui.mAnimator:SetInteger("Switch", self.data.id - 997)
end

function UIActivityCafeDrinkDetailsDialog:UpdateInfo()
  self.ui.mText_Name.text = self.machineTablData.article_name_show.str
  self.ui.mText_Info.text = self.machineTablData.article_desc_show.str
  self.ui.mImg_Icon.sprite = IconUtils.GetCafeIcon(self.machineTablData.article_button)
  self.ui.mText_Time.text = ""
  self.idleData = NetCmdActivitySimData:GetIdleData(self.data.id, self.data.level)
  if self.idleData ~= nil then
    self.itemTable = {}
    self.ui.mText_Time.text = self.idleData.outer_cd .. "s"
    self:InitItem(self.idleData.idle_item, self.idleData.idle_num, self.ui.mTrans_ItemRoot1, false)
    self:InitItem(self.idleData.outer_item, self.idleData.outer_num, self.ui.mTrans_ItemRoot2, false)
    self:InitItem(self.idleData.synthesis_item, self.idleData.synthesis_num, self.ui.mTrans_ItemRoot3, true)
    local idleItemData = TableData.GetItemData(self.idleData.idle_item)
    self.ui.mImg_IconIdle.sprite = IconUtils.GetItemIcon(idleItemData.icon)
  end
  self:UpdateLeftTime()
end

function UIActivityCafeDrinkDetailsDialog:OnUpdate()
  self.ui.mAnimator_Stock:SetBool("Bool", self.machineData.LastProduceTime == 0)
end

function UIActivityCafeDrinkDetailsDialog:UpdateLeftTime()
  self.machineData = NetCmdActivitySimData:GetMachineDataById(self.data.id)
  setactive(self.ui.mTrans_Warning, self.machineData.LastProduceTime == 0)
  setactive(self.ui.mTrans_InProgress, self.machineData.LastProduceTime ~= 0)
  setactive(self.ui.mTrans_WarningText, self.machineData.LastProduceTime == 0)
  local itemNum = NetCmdItemData:GetItemCountById(self.idleData.idle_item)
  itemNum = CS.LuaUIUtils.GetMaxNumberText(itemNum)
  self.ui.mText_Stock.text = TableData.GetActivityHint(271147, self.activity_id, 2, self.module_id, self.config_id) .. itemNum
  if self.machineData.LastProduceTime == 0 then
    self.ui.mText_Warning.text = TableData.GetActivityHint(271116, self.activity_id, 2, self.module_id, self.config_id)
    self.ui.mText_State.text = TableData.GetActivityHint(271176, self.activity_id, 2, self.module_id, self.config_id)
  else
    self.ui.mText_Warning.text = TableData.GetActivityHint(271115, self.activity_id, 2, self.module_id, self.config_id)
    if self.idleData then
      local leftCount = math.floor(NetCmdItemData:GetItemCountById(self.idleData.idle_item) / self.idleData.idle_num)
      local endTime = self.machineData.LastProduceTime + leftCount * self.idleData.outer_cd
      local timeStr = CS.TimeUtils.LeftTimeToShowFormat(endTime - CGameTime:GetTimestamp())
      self.ui.mText_State.text = string_format(TableData.GetActivityHint(271114, self.activity_id, 2, self.module_id, self.config_id), timeStr)
      setactive(self.ui.mTrans_WarningText, NetCmdItemData:GetItemCountById(self.idleData.idle_item) <= self.idleData.idle_alarm)
    end
  end
end

function UIActivityCafeDrinkDetailsDialog:InitItem(id, count, parent, isFall)
  local item = UICafeDrinkDetailItem.New()
  table.insert(self.itemTable, item)
  local data = {
    id = id,
    count = count,
    isFall = isFall,
    moduleId = self.module_id,
    configId = self.activity_id
  }
  item:InitCtrl(parent.gameObject, data)
end

function UIActivityCafeDrinkDetailsDialog.CloseSelf()
  UIManager.CloseUI(UIDef.UIActivityCafeDrinkDetailsDialog)
end

function UIActivityCafeDrinkDetailsDialog:OnClose()
  MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.SimCafeDropTimeout, self.onSimCafeDropTimeout)
  if self.itemTable ~= nil then
    self:ReleaseCtrlTable(self.itemTable)
    self.itemTable = nil
  end
end
