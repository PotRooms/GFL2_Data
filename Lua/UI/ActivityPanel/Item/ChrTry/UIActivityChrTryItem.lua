require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
require("UI.Common.UICommonItem")
UIActivityChrTryItem = class("UIActivityChrTryItem", UIActivityItemBase)
UIActivityChrTryItem.__index = UIActivityChrTryItem

function UIActivityChrTryItem:OnInit()
  self.bgMap = {}
end

function UIActivityChrTryItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  local rewards = NetCmdActivityChrTryData:GetRewarShow(self.mActivityID)
  NetCmdActivityChrTryData:ViewChrTry(self.mActivityID)
  if self.UICommonItems ~= nil then
    self:ReleaseCtrlTable(self.UICommonItems, true)
  end
  self.UICommonItems = {}
  for _, key in pairs(rewards.Keys) do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mTrans_Content)
    table.insert(self.UICommonItems, item)
    local itemData = TableData.GetItemData(key)
    item:SetItemByStcData(itemData, rewards[key])
  end
  local chrTryData = TableDataBase.listEventRoleTrialDatas:GetDataById(self.mActivityID)
  for id, obj in pairs(self.bgMap) do
    setactive(obj, id == self.mActivityID)
  end
  if self.bgMap[self.mActivityID] == nil then
    local obj = UIUtils.GetGizmosPrefab("Activity/ChrTry/" .. chrTryData.bg_image .. ".prefab", self)
    self.bgMap[self.mActivityID] = instantiate(obj, self.ui.mTrans_Bg)
  end
  self.ui.mImg_Num.sprite = IconUtils.GetChrTrySprite(chrTryData.ui_param)
  local gachaId = tonumber(chrTryData.gacha_id)
  local gachaData = TableDataBase.listGachaDatas:GetDataById(gachaId)
  if gachaData ~= nil then
    local gunId = tonumber(gachaData.gun_up_character)
    local gunData = TableData.listGunDatas:GetDataById(gunId)
    local dutyData = TableData.listGunDutyDatas:GetDataById(gunData.duty)
    self.ui.mImg_Duty.sprite = IconUtils.GetGunTypeIcon(dutyData.icon .. "_ChrTry")
    self.ui.mText_GunName.text = gunData.name.str
    UIUtils.GetButtonListener(self.ui.mBtn_Preview.gameObject).onClick = function()
      local listType = CS.System.Collections.Generic.List(CS.System.Int32)
      local mlist = listType()
      mlist:Add(gunId)
      mlist:Add(FacilityBarrackGlobal.ShowContentType.UIGachaPreview)
      mlist:Add(gachaId)
      UISystem:JumpByID(4001, false, mlist)
    end
    UIUtils.GetButtonListener(self.ui.mBtn_Video.gameObject).onClick = function()
      CS.CriWareVideoController.StartPlay(gunData.gacha_get_timeline .. ".usm", CS.CriWareVideoType.eVideoPath, function()
      end, true, 1, false, -1, 0, {
        gunData.gacha_get_audio,
        gunData.gacha_get_voice
      })
    end
    local stageId = tonumber(gachaData.gun_up_character_stage)
    local stageData = TableData.listStageDatas:GetDataById(stageId)
    UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
      SceneSys:OpenBattleSceneForGacha(stageData)
    end
    local record = NetCmdStageRecordData:GetStageRecordById(stageId)
    for _, item in pairs(self.UICommonItems) do
      item:SetReceivedIcon(record.first_pass_time ~= 0)
    end
  end
end

function UIActivityChrTryItem:OnHide()
end

function UIActivityChrTryItem:OnTop()
  self:OnShow()
end

function UIActivityChrTryItem:OnClose()
  self:ReleaseCtrlTable(self.UICommonItems, true)
  self.bgMap = {}
end
