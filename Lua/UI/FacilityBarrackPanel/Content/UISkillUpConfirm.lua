UISkillUpConfirm = class("UISkillContent", UIBaseCtrl)
UISkillUpConfirm.__index = UISkillUpConfirm
UISkillUpConfirm.PrefabPath = "Character/ChrSkillUpPanelV2.prefab"

function UISkillUpConfirm:__InitCtrl()
  self.mTrans_Confirm = self:GetRectTransform("Root/GrpConfirm/ChrSkillUpPanelV2")
  self.mBtn_Cancel = self:GetButton("Root/GrpDialog/GrpAction/BtnCancel/Btn_Content")
  self.mBtn_Confirm = self:GetButton("Root/GrpDialog/GrpAction/BtnConfirm/Btn_Content")
  self.mBtn_ConfirmBgClose = self:GetButton("Root/GrpBg/Btn_Close")
  self.mBtn_ConfirmClose = self:GetButton("Root/GrpDialog/GrpTop/GrpClose/Btn_Close")
  self.mText_ConfirmName = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpText/Text_Name")
  self.mImage_ConfirmIcon = self:GetImage("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpSkillIcon/GrpIcon/Img_Icon")
  self.mText_ConfirmCurLevel = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpLevelUp/GrpTextNow/Text_Level")
  self.mText_ConfirmNextLevel = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpLevelUp/GrpTextSoon/Text_Level")
  self.mText_ConfirmDesc = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillUp/GrpAllSkillDescription/GrpDescribe/Viewport/Content/Text_SkillUp")
  self.mTrans_CostItem = self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpConsume/GrpItem/ComItemV2")
  self.mText_CoinCost = self:GetText("Root/GrpDialog/GrpCenter/GrpConsume/GrpTextConsume/Text_Num")
  self.mImage_CoinIcon = self:GetImage("Root/GrpDialog/GrpCenter/GrpConsume/GrpTextConsume/GrpGoldIcon/Img_Bg")
end

function UISkillUpConfirm:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
end
