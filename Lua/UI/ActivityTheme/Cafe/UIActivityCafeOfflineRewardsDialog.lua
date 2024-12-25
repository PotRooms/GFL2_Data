require("UI.UIBasePanel")
UIActivityCafeOfflineRewardsDialog = class("UIActivityCafeOfflineRewardsDialog", UIBasePanel)
UIActivityCafeOfflineRewardsDialog.__index = UIActivityCafeOfflineRewardsDialog

function UIActivityCafeOfflineRewardsDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityCafeOfflineRewardsDialog:OnInit(root, data)
  self.super.SetRoot(UIActivityCafeOfflineRewardsDialog, root)
  self.module_id = 3003
  self.config_id = 101
  self.activity_id = NetCmdActivitySimData.offcialConfigId
  CSUIUtils.GetAndSetActivityHintText(root, self.activity_id, 2, self.module_id, self.config_id)
  self.data = data
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:RegisterEvent()
  self:UpdateInfo()
end

function UIActivityCafeOfflineRewardsDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BgClose.gameObject).onClick = function()
    self.CloseSelf()
  end
end

function UIActivityCafeOfflineRewardsDialog:UpdateInfo()
  self.infoList = {}
  if self.data.rewards.TotalSoldAdd > 0 then
    self:CreateInfoObj(4, self.data.rewards.TotalSoldAdd, 0)
  end
  if 0 < self.data.rewards.CustomerAdd then
    self:CreateInfoObj(3, self.data.rewards.CustomerAdd, 0)
  end
  for key, value in pairs(self.data.rewards.MachineProduct) do
    self:CreateInfoObj(1, key, value)
  end
  for key, value in pairs(self.data.rewards.RecipeProduce) do
    self:CreateInfoObj(2, key, value)
  end
end

function UIActivityCafeOfflineRewardsDialog:CreateInfoObj(type, param1, param2)
  local obj = instantiate(self.ui.mObj_InfoPrefab.gameObject, self.ui.mTrans_Content.transform)
  table.insert(self.infoList, obj)
  setactive(obj, true)
  local img_icon = obj.transform:Find("GrpIcon/Img_Icon"):GetComponent(typeof(CS.UnityEngine.UI.Image))
  local text_info = obj.transform:Find("Text_Info"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  if type == 1 then
    local itemData = TableData.GetItemData(param1)
    img_icon.sprite = IconUtils.GetItemIcon(itemData.icon)
    text_info.text = string_format(TableData.GetActivityHint(271200, self.activity_id, 2, self.module_id, self.config_id), itemData.Name.str, tostring(param2))
  elseif type == 2 then
    local itemData = TableData.listSimRecipeDatas:GetDataById(param1)
    img_icon.sprite = IconUtils.GetItemIcon(itemData.recipe_icon)
    text_info.text = string_format(TableData.GetActivityHint(271201, self.activity_id, 2, self.module_id, self.config_id), itemData.recipe_name.str, tostring(param2))
  elseif type == 3 then
    img_icon.sprite = IconUtils.GetItemIcon("Item_Icon_ActivityCafe_Customer")
    text_info.text = string_format(TableData.GetActivityHint(271199, self.activity_id, 2, self.module_id, self.config_id), tostring(param1))
  elseif type == 4 then
    img_icon.sprite = IconUtils.GetItemIcon("Item_Icon_ActivityCafe_Turnover")
    text_info.text = string_format(TableData.GetActivityHint(271198, self.activity_id, 2, self.module_id, self.config_id), tostring(param1))
  end
end

function UIActivityCafeOfflineRewardsDialog.CloseSelf()
  UIManager.CloseUI(UIDef.UIActivityCafeOfflineRewardsDialog)
end

function UIActivityCafeOfflineRewardsDialog:OnClose()
  for _, obj in pairs(self.infoList) do
    gfdestroy(obj)
  end
  self.infoList = {}
end
