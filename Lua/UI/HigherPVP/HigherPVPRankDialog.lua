require("UI.UIBasePanel")
require("UI.HigherPVP.HigherPVPRankItem")
require("UI.Common.UICommonPlayerAvatarItem")
require("UI.HigherPVP.Btn_ComChrAvatarRankItem")
HigherPVPRankDialog = class("HigherPVPRankDialog", UIBasePanel)
HigherPVPRankDialog.__index = HigherPVPRankDialog

function HigherPVPRankDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPRankDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:OnBtnClick()
  self:InitDefenLineUp()
  self.pvpRankList = {}
  
  function self.ItemProvider(renderData)
    self:ItemProviderData(renderData)
  end
  
  function self.ItemRenderer(index, renderData)
    self:ItemRendererData(index, renderData)
  end
  
  self.ui.mSuperGridScrollerController_PlayerInfoList.itemCreated = self.ItemProvider
  self.ui.mSuperGridScrollerController_PlayerInfoList.itemRenderer = self.ItemRenderer
end

function HigherPVPRankDialog:InitDefenLineUp()
  self.selfAvatarList = {}
  for i = 1, 4 do
    local cell = Btn_ComChrAvatarRankItem.New()
    cell:InitCtrl(self.ui.mTrans_ChrList)
    table.insert(self.selfAvatarList, cell)
  end
end

function HigherPVPRankDialog:OnBtnClick()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.HigherPVPRankDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
end

function HigherPVPRankDialog:RefreshInfo()
  self.pvpRankList = NetCmdHigherPVPData:GetPVPRankList()
  setactive(self.ui.mTrans_Empty.gameObject, self.pvpRankList.Count == 0)
  self.ui.mSuperGridScrollerController_PlayerInfoList.numItems = self.pvpRankList.Count
  self.ui.mSuperGridScrollerController_PlayerInfoList:Refresh()
  setactive(self.ui.mSuperGridScrollerController_PlayerInfoList.gameObject, self.pvpRankList.Count > 0)
end

function HigherPVPRankDialog:OnInit(root, data)
end

function HigherPVPRankDialog:ItemProviderData(renderData)
  local itemView = HigherPVPRankItem.New()
  itemView:InitCtrlWithoutInstantiate(renderData.gameObject)
  renderData.data = itemView
end

function HigherPVPRankDialog:ItemRendererData(index, renderData)
  local item = renderData.data
  local data = self.pvpRankList[index]
  item:SetData(data)
end

function HigherPVPRankDialog:RefreshMeRankInfo()
  local selfRankInfo = NetCmdHigherPVPData:GetMeRankInfo()
  if self.playerAvatar == nil then
    self.playerAvatar = UICommonPlayerAvatarItem.New()
    self.playerAvatar:InitCtrl(self.ui.mTrans_PlayerAvatar)
  end
  self.playerAvatar:SetData(TableData.GetPlayerAvatarIconById(selfRankInfo.user.Portrait, LuaUtils.EnumToInt(selfRankInfo.user.Sex)))
  if selfRankInfo.user.PortraitFrame and selfRankInfo.user.PortraitFrame > 0 then
    local frameData = TableData.listHeadFrameDatas:GetDataById(selfRankInfo.user.PortraitFrame, true)
    if frameData then
      self.playerAvatar:SetFrameDataOut(frameData.icon)
    end
  end
  self.ui.mText_PlayerName.text = selfRankInfo.user.Name
  self.ui.mText_Level.text = TableData.GetHintById(82001) .. selfRankInfo.user.Level
  if selfRankInfo.rankInfo then
    if 0 < selfRankInfo.rankInfo.Rank and selfRankInfo.rankInfo.Rank <= self.maxRankCount then
      self.ui.mText_Num.text = selfRankInfo.rankInfo.Rank
      setactive(self.ui.mTrans_Text.gameObject, false)
    elseif 0 < NetCmdHigherPVPData:GetSelfRankPercent() then
      self.ui.mText_Num.text = NetCmdHigherPVPData:GetSelfRankPercent() .. "%"
      setactive(self.ui.mTrans_Text.gameObject, false)
    else
      self.ui.mText_Num.text = ""
      setactive(self.ui.mTrans_Text.gameObject, true)
    end
    self.ui.mText_Num1.text = selfRankInfo.rankInfo.Point
    for i = 1, #self.selfAvatarList do
      local cell = self.selfAvatarList[i]
      if i <= selfRankInfo.rankInfo.Avatars.Count then
        cell:SetData(selfRankInfo.rankInfo.Avatars[i - 1], selfRankInfo.user)
      else
        cell:SetData(nil, selfRankInfo.user)
      end
    end
  else
    self.ui.mText_Num1.text = 0
    self.ui.mText_Num.text = TableData.GetHintById(130006)
    for i = 1, #self.selfAvatarList do
      local cell = self.selfAvatarList[i]
      cell:SetData(nil, selfRankInfo.user)
    end
  end
end

function HigherPVPRankDialog:CleanRankReqTimer()
  if self.rankReqTimer then
    self.rankReqTimer:Stop()
    self.rankReqTimer = nil
  end
end

function HigherPVPRankDialog:StartRankReq()
  self:CleanRankReqTimer()
  local repeatCount = math.ceil(self.maxRankCount / NetCmdHigherPVPData.pvpRanStep)
  self.rankReqTimer = TimerSys:DelayCall(1.2, function()
    self.ui.mAutoScrollFade_Content.enabled = false
    if not NetCmdHigherPVPData:RankSucc() then
      self:CleanRankReqTimer()
      return
    end
    local startIndex = self.pvpRankList.Count + 1
    if startIndex > self.maxRankCount then
      return
    end
    local endIndex = startIndex + NetCmdHigherPVPData.pvpRanStep - 1
    if endIndex >= self.maxRankCount then
      endIndex = self.maxRankCount
    end
    NetCmdHigherPVPData:MsgCsHighPvpRank(false, startIndex, endIndex, function(ret)
      if ret == ErrorCodeSuc then
        self.pvpRankList = NetCmdHigherPVPData:GetPVPRankList()
        self.ui.mSuperGridScrollerController_PlayerInfoList.numItems = self.pvpRankList.Count
        self.ui.mSuperGridScrollerController_PlayerInfoList:Refresh()
      end
    end)
  end, nil, repeatCount)
end

function HigherPVPRankDialog:OnShowStart()
  self.maxRankCount = TableDataBase.GlobalSystemData.HighPVPRankingListNum
  NetCmdHigherPVPData:MsgCsHighPvpRank(true, 1, NetCmdHigherPVPData.pvpRanStep, function(ret)
    if ret == ErrorCodeSuc then
      self.ui.mAutoScrollFade_Content.enabled = true
      self:RefreshMeRankInfo()
      self:RefreshInfo()
      self.ui.mSuperGridScrollerController_PlayerInfoList:ScrollTo(0)
      self:StartRankReq()
    end
  end)
end

function HigherPVPRankDialog:OnShowFinish()
end

function HigherPVPRankDialog:OnTop()
end

function HigherPVPRankDialog:OnBackFrom()
end

function HigherPVPRankDialog:OnClose()
  if self.playerAvatar then
    self.playerAvatar:OnRelease()
    self.playerAvatar = nil
  end
  self:CleanRankReqTimer()
  NetCmdHigherPVPData:CleanRankSucc()
end

function HigherPVPRankDialog:OnHide()
end

function HigherPVPRankDialog:OnHideFinish()
end

function HigherPVPRankDialog:OnRelease()
end
