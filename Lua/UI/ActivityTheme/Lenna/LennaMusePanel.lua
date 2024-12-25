require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
require("UI.ActivityTheme.Lenna.Item.LennaMuseItem")
require("UI.ActivityTour.Btn_ActivityMuseExchangeLeftItem")
require("UI.ActivityTour.Btn_ActivityMuseExchangeRightItem")
LennaMusePanel = class("LennaMusePanel", UIBasePanel)
LennaMusePanel.__index = LennaMusePanel

function LennaMusePanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function LennaMusePanel:OnAwake(root)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  setactivewithcheck(self.ui.mTrans_Collect, true)
  self:AddBtnListener()
end

function LennaMusePanel:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back).onClick = function()
    UIManager.CloseUI(UIDef.LennaMusePanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Cancel).onClick = function()
    self.themeId = NetCmdRecentActivityData:GetNowOpenThemeId(self.themeId)
    if not NetCmdRecentActivityData:ThemeActivityIsOpen(self.themeId) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      UIManager.CloseUI(UIDef.LennaMusePanel)
      return
    end
    for i = 1, self.collectDataList.Count do
      local itemNum = NetCmdItemData:GetItemCount(self.collectDataList[i - 1].id)
      if itemNum <= 0 then
        local hint = TableData.GetActivityHint(270185, self.activityID, 2, 5001, self.museID)
        CS.PopupMessageManager.PopupString(hint)
        return
      end
    end
    NetCmdThemeData:SendActiveInspiration(self.themeId, function(ret)
      if ret == ErrorCodeSuc then
        self.isActiveCollect = false
        self.ui.mAnimator_Collect:SetTrigger("Activation")
        self:CleanOpenTime()
        self.openTime = TimerSys:DelayCall(1, function()
          UISystem:OpenCommonReceivePanel()
          self:CleanOpenTime()
          self:OnTop()
        end)
      end
    end)
  end
end

function LennaMusePanel:ManualUI()
  setactivewithcheck(self.ui.mTrans_Item, false)
  self.firstDataList = NetCmdThemeData:GetCollectRewardList(self.museID, 1)
  self.secondDataList = NetCmdThemeData:GetCollectRewardList(self.museID, 2)
  self.firstUIList = {}
  self.secondUIList = {}
  self.secTextList = {}
  self.secGoList = {}
  for i = 1, self.firstDataList.Count do
    local data = self.firstDataList[i - 1]
    local itemData = self:GetItemData(data.reward_item)
    local collCount = NetCmdThemeData:GetCollectItemCount(data.id)
    for j = 1, #itemData do
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_Content)
      item:SetItemData(itemData[j].itemId, itemData[j].itemNum, nil, nil, nil, nil, nil, function()
        TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(itemData[j].itemId))
      end)
      item:SetReceivedIcon(collCount >= data.reward_count)
      table.insert(self.firstUIList, item)
    end
  end
  for i = 1, self.secondDataList.Count do
    local GO = instantiate(self.ui.mTrans_Item, self.ui.mTrans_ItemList)
    GO.transform:SetAsLastSibling()
    setactivewithcheck(GO, true)
    local data = self.secondDataList[i - 1]
    local collCount = NetCmdThemeData:GetCollectItemCount(data.id)
    local itemData = self:GetItemData(data.reward_item)
    for j = 1, #itemData do
      local item = UICommonItem.New()
      item:InitCtrl(GO.transform)
      item:SetItemData(itemData[j].itemId, itemData[j].itemNum, nil, nil, nil, nil, nil, function()
        TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(itemData[j].itemId))
      end)
      item:SetReceivedIcon(collCount >= data.reward_count)
      local txt = GO.transform:Find("TextNum/Text_Num"):GetComponent(typeof(CS.UnityEngine.UI.Text))
      txt.text = TableData.GetHintById(103124) .. data.reward_count - collCount
      table.insert(self.secTextList, txt)
      table.insert(self.secondUIList, item)
      table.insert(self.secGoList, GO)
    end
  end
  self.collectDataList = NetCmdThemeData:GetCollectDataList(self.museID)
  self.collectItemList = {}
  for i = 1, self.ui.mTrans_Item1.childCount do
    local index = i - 1
    local trans = self.ui.mTrans_Item1:GetChild(index)
    local item = LennaMuseItem.New()
    item:InitCtrl(trans)
    item:SetData(self.collectDataList[index])
    table.insert(self.collectItemList, item)
  end
end

function LennaMusePanel:CleanOpenTime()
  if self.openTime then
    self.openTime:Stop()
    self.openTime = nil
  end
end

function LennaMusePanel:GetItemData(rewardList)
  local itemData = {}
  for k, v in pairs(rewardList) do
    local item = {}
    item.itemId = k
    item.itemNum = v
    table.insert(itemData, item)
  end
  return itemData
end

function LennaMusePanel:UpdateInfo()
  self.museData = TableData.listCollectionThemeDatas:GetDataById(self.museID)
  if self.museData then
    self:UpdateCollectInfo()
    self:UpdateCollectReward()
    self:UpdateRewardCount()
  end
end

function LennaMusePanel:UpdateCollectInfo()
  CSUIUtils.GetAndSetActivityHintText(self.mUIRoot, self.activityID, 2, 5001, self.museID)
  self.ui.mText_Name.text = self.museData.name.str
  self.ui.mText_Description.text = self.museData.function_desc.str
  local collectCount = NetCmdThemeData:GetCurrActiCount()
  local collTotolCount = NetCmdThemeData:GetTotalActiCount(self.museData.reward_group)
  self.ui.mText_Num.text = "<color=#d8bf74>" .. collectCount .. "</color>/" .. collTotolCount .. TableData.GetHintById(270204)
  setactivewithcheck(self.ui.mTrans_Btn, collectCount < collTotolCount)
  setactivewithcheck(self.ui.mTrans_Receive, collectCount >= collTotolCount)
end

function LennaMusePanel:UpdateCollectReward()
  local data = self.firstDataList[0]
  local collectCount = NetCmdThemeData:GetCollectItemCount(data.id)
  for _, v in ipairs(self.firstUIList) do
    v:SetReceivedIcon(collectCount >= data.reward_count)
  end
  for k, v in ipairs(self.secondUIList) do
    local secondData = self.secondDataList[k - 1]
    local count = NetCmdThemeData:GetCollectItemCount(secondData.id)
    v:SetReceivedIcon(count >= secondData.reward_count)
    local secTxt = self.secTextList[k]
    if secTxt then
      secTxt.text = TableData.GetHintById(103124) .. secondData.reward_count - count
    end
  end
end

function LennaMusePanel:UpdateRewardCount()
  for k, v in ipairs(self.collectItemList) do
    v:SetData(self.collectDataList[k - 1])
  end
end

function LennaMusePanel:OnInit(root, data)
  self.themeId = data.themeId
  self.museID = data.moduleId
  self.activityID = data.activity
  
  function LennaMusePanel.RefreshInfo()
    self:UpdateRewardCount()
    self:UpdateMySubList()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnThemeCollectUpdate, LennaMusePanel.RefreshInfo)
end

function LennaMusePanel:OnShowStart()
  self:ManualUI()
  NetCmdThemeData:SendThemeInspirationInfo(self.themeId, function(ret)
    self:UpdateInfo()
  end)
end

function LennaMusePanel:OnTop()
  self:UpdateCollectInfo()
  self:UpdateCollectReward()
  self:UpdateRewardCount()
end

function LennaMusePanel:OnBackFrom()
  self:UpdateCollectInfo()
  self:UpdateCollectReward()
  self:UpdateRewardCount()
end

function LennaMusePanel:ReleaseReward()
  self:ReleaseCtrlTable(self.firstUIList, true)
  self:ReleaseCtrlTable(self.secondUIList, true)
  self:ReleaseCtrlTable(self.collectItemList, false)
  for i = #self.secGoList, 1, -1 do
    gfdestroy(self.secGoList[i])
  end
  self.firstUIList = nil
  self.secondUIList = nil
  self.collectItemList = nil
  self.secGoList = nil
end

function LennaMusePanel:OnClose()
  self:CleanOpenTime()
  self:ReleaseReward()
end

function LennaMusePanel:OnHide()
end

function LennaMusePanel:OnHideFinish()
end

function LennaMusePanel:OnRelease()
  self:CleanOpenTime()
end
