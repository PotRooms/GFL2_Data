require("UI.UIBasePanel")
require("UI.Lounge.DormGlobal")
ComBtnInputKeyPC = class("ComBtnInputKeyPC", UIBaseCtrl)
ComBtnInputKeyPC.__index = ComBtnInputKeyPC

function ComBtnInputKeyPC:ctor()
end

function ComBtnInputKeyPC:InitCtrl(obj, needHideObjList, panel, Key, KeyStr, callback)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self.PCKeyUI = {}
  self:LuaUIBindTable(CS.LuaUIUtils.GetUIPCKeyObj(self.ui.mPCKey.transform), self.PCKeyUI)
  self.panel = panel
  self.needHideObjList = {}
  self.needHideObjList = needHideObjList
  self.isShow = DormGlobal.IsShowUI
  self.PCKeyUI.mText_InputKey.text = KeyStr
  self.key = Key
  self.KeyStr = KeyStr
  self.callback = callback
  self.clickBtn = nil
  if self.isShow then
    self.ui.mText_Show.text = TableData.GetHintById(280018)
  else
    self.ui.mText_Show.text = TableData.GetHintById(280017)
  end
  self:Content()
end

function ComBtnInputKeyPC:Content()
  self:AddKeyListener()
end

function ComBtnInputKeyPC:AddKeyListener()
  function self.showFunc()
    if self.isShow then
      self.isShow = false
      
      if self.callback then
        self.callback()
      end
      for i = 1, #self.needHideObjList do
        local obj = self.needHideObjList[i]
        setactivewithcheck(obj, false)
      end
      self.ui.mText_Show.text = TableData.GetHintById(280017)
    else
      self.isShow = true
      if self.callback then
        self.callback()
      end
      for i = 1, #self.needHideObjList do
        local obj = self.needHideObjList[i]
        setactivewithcheck(obj, true)
      end
      self.ui.mText_Show.text = TableData.GetHintById(280018)
    end
  end
  
  UIUtils.GetButtonListener(self.PCKeyUI.mBtn_KeyPC.gameObject).onClick = function()
    self.showFunc()
  end
  if self.key == KeyCode.Mouse2 then
    self.clickBtn = self.panel.ui.mBtn_Reset
    self.ui.mText_Show.text = TableData.GetHintById(230019)
  elseif self.key == KeyCode.H then
    self.clickBtn = self.PCKeyUI.mBtn_KeyPC
  end
  setactivewithcheck(self.ui.mTrans_Icon, self.key == KeyCode.Mouse2)
  setactivewithcheck(self.ui.mPCKey, self.key ~= KeyCode.Mouse2)
  self.panel:RegistrationKeyboard(self.key, self.clickBtn)
end

function ComBtnInputKeyPC:OnRelease()
  gfdestroy(self:GetRoot())
end
