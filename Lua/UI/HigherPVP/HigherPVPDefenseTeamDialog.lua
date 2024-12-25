require("UI.UIBasePanel")
require("UI.Common.UICommonArrowBtnItem")
require("UI.Common.ComChrInfoItemV2")
HigherPVPDefenseTeamDialog = class("HigherPVPDefenseTeamDialog", UIBasePanel)
HigherPVPDefenseTeamDialog.__index = HigherPVPDefenseTeamDialog

function HigherPVPDefenseTeamDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPDefenseTeamDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:InitDefendUI()
  self:OnBtnClick()
end

function HigherPVPDefenseTeamDialog:InitDefendUI()
  self.defendUIList = {}
  for i = 1, 4 do
    local defendCell = ComChrInfoItemV2.New()
    defendCell:InitCtrl(self.ui.mTrans_Chr)
    table.insert(self.defendUIList, defendCell)
  end
  self.selectItemUIList = {}
  table.insert(self.selectItemUIList, self:GetCell(self.ui.mTrans_DotItem))
end

function HigherPVPDefenseTeamDialog:GetCell(root)
  local cell = {}
  cell.Trans_ImgNow = root:Find("Trans_ImgNow").gameObject
  cell.Trans_ImgSel = root:Find("Trans_ImgSel").gameObject
  cell.Trans_ImgComplete = root:Find("Trans_ImgComplete").gameObject
  return cell
end

function HigherPVPDefenseTeamDialog:OnBtnClick()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    NetCmdHigherPVPData.currSelectMapId = 0
    UIManager.CloseUI(UIDef.HigherPVPDefenseTeamDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Edit.gameObject).onClick = function()
    self:OnClickEditor()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Edit2.gameObject).onClick = function()
    self:OnClickEditor()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_PreGun.gameObject).onClick = function()
    self:OnClickArrow(-1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_NextGun.gameObject).onClick = function()
    self:OnClickArrow(1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    if self.defendDataList == nil or self.defendDataList.Count == 0 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(290713))
      return
    end
    local mapData = self.mapIdDatas[self.selectMapIndex]
    NetCmdHigherPVPData:MsgCsHighPvpUseCurrMap(mapData.id, function(ret)
      if ret == ErrorCodeSuc then
        self.ui.mAnimator_Root:SetInteger("Action", 1)
        self.currMapId = NetCmdHigherPVPData:GetHigherPVPCurrMapId()
      end
    end)
  end
end

function HigherPVPDefenseTeamDialog:OnClickEditor()
  local mapData = self.mapIdDatas[self.selectMapIndex]
  NetCmdHigherPVPData.currSelectMapId = mapData.id
  local pvpStageParam = CS.PvpStageParam()
  pvpStageParam.PvpPreview = false
  pvpStageParam.PvpDefendMapId = mapData.id
  pvpStageParam.isHighPVP = true
  NetCmdHigherPVPData:OpenBattleSceneForHigherPVP(pvpStageParam)
end

function HigherPVPDefenseTeamDialog:RefreshBtnState()
  setactive(self.ui.mBtn_PreGun.gameObject, self.selectMapIndex > 0)
  setactive(self.ui.mBtn_NextGun.gameObject, self.selectMapIndex < self.maxIndex - 1)
  self.ui.mAnimator_Root:SetBool("Previous", self.selectMapIndex > 0)
  self.ui.mAnimator_Root:SetBool("Next", self.selectMapIndex < self.maxIndex - 1)
end

function HigherPVPDefenseTeamDialog:OnClickArrow(changeNum)
  self.selectMapIndex = self.selectMapIndex + changeNum
  if self.selectMapIndex < 0 then
    self.selectMapIndex = 0
  end
  if self.selectMapIndex > self.maxIndex - 1 then
    self.selectMapIndex = self.maxIndex - 1
  end
  self:RefreshBtnState()
  self:UpdateLineUp()
  self:RefreshSelectItem()
end

function HigherPVPDefenseTeamDialog:GetCurrMapIndex(currMapId)
  local index = 0
  for i = 0, self.mapIdDatas.Count - 1 do
    if currMapId == self.mapIdDatas[i].id then
      index = i
      break
    end
  end
  return index
end

function HigherPVPDefenseTeamDialog:RefreshInfo()
  self.currMapId = NetCmdHigherPVPData:GetHigherPVPCurrMapId()
  self.currSeasonMapGroupId = NetCmdHigherPVPData:GetHigherPVPSeasonMapGroupId()
  if self.arrowBtn == nil then
    self.arrowBtn = UICommonArrowBtnItem.New()
    self.arrowBtn:InitObj(self.ui.mObj_ViewSwitch)
  end
  self:UpdateMapData()
  self.arrowBtn:SetLeftArrowActiveFunction(function()
    return self.selectMapIndex > 0
  end)
  self.arrowBtn:SetRightArrowActiveFunction(function()
    return self.selectMapIndex < self.maxIndex - 1
  end)
  self.arrowBtn:RefreshArrowActive()
end

function HigherPVPDefenseTeamDialog:UpdateSelectItem()
  if #self.selectItemUIList < self.mapIdDatas.Count then
    local count = #self.selectItemUIList + 1
    for i = count, self.mapIdDatas.Count do
      local go = instantiate(self.ui.mTrans_DotItem, self.ui.mTrans_Dot)
      go.transform:SetAsLastSibling()
      table.insert(self.selectItemUIList, self:GetCell(go))
    end
  end
end

function HigherPVPDefenseTeamDialog:RefreshSelectItem()
  for i = 1, #self.selectItemUIList do
    setactive(self.selectItemUIList[i].Trans_ImgSel, self.selectMapIndex == i - 1)
  end
end

function HigherPVPDefenseTeamDialog:UpdateMapData()
  self.mapIdDatas = NetCmdHigherPVPData:GetMapGroupDatas(self.currSeasonMapGroupId)
  self:UpdateSelectItem()
  if NetCmdHigherPVPData.currSelectMapId > 0 then
    self.selectMapIndex = self:GetCurrMapIndex(NetCmdHigherPVPData.currSelectMapId)
  else
    self.selectMapIndex = self:GetCurrMapIndex(self.currMapId)
  end
  self.maxIndex = self.mapIdDatas.Count
  self:RefreshSelectItem()
  self:UpdateLineUp()
end

function HigherPVPDefenseTeamDialog:UpdateLineUp()
  local mapData = self.mapIdDatas[self.selectMapIndex]
  if mapData then
    self.ui.mText_Title.text = mapData.map_name.str
    if self.currMapId == mapData.id then
      self.ui.mAnimator_Root:SetInteger("Action", 2)
    else
      self.ui.mAnimator_Root:SetInteger("Action", 0)
    end
    setactive(self.ui.mBtn_Confirm.gameObject, self.currMapId ~= mapData.id)
    self.ui.mText_Num.text = NetCmdHigherPVPData:GetHigherPVPEffectByMapId(mapData.id)
    self.defendDataList = NetCmdHigherPVPData:GetPVPDefendGunListByMapId(mapData.id)
    for i = 1, #self.defendUIList do
      local defendCell = self.defendUIList[i]
      if i <= self.defendDataList.Count then
        defendCell:RefreshLineUp(self.defendDataList[i - 1], nil, false)
      else
        defendCell:RefreshLineUp(nil, nil, false)
      end
    end
  end
end

function HigherPVPDefenseTeamDialog:OnInit(root, data)
  setactive(self.ui.mBtn_Home.gameObject, false)
end

function HigherPVPDefenseTeamDialog:OnShowStart()
  self:RefreshInfo()
end

function HigherPVPDefenseTeamDialog:OnShowFinish()
end

function HigherPVPDefenseTeamDialog:OnTop()
end

function HigherPVPDefenseTeamDialog:OnBackFrom()
  self:RefreshInfo()
end

function HigherPVPDefenseTeamDialog:OnRecover()
  self:RefreshInfo()
end

function HigherPVPDefenseTeamDialog:OnClose()
  NetCmdHigherPVPData:CleanDefendEffectNum()
end

function HigherPVPDefenseTeamDialog:OnHide()
end

function HigherPVPDefenseTeamDialog:OnHideFinish()
end

function HigherPVPDefenseTeamDialog:OnRelease()
end
