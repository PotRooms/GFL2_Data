require("UI.UIBaseView")
UIUAVSkillInfoPanelView = class("UIUAVSkillInfoPanelView", UIBaseView)
UIUAVSkillInfoPanelView.__index = UIUAVSkillInfoPanelView

function UIUAVSkillInfoPanelView:__InitCtrl()
  self.mBtn_BgClose = self:GetButton("Root/GrpBg/Btn_Close")
  self.mBtn_Close = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpTop/GrpClose"))
  self.mText_TitleName = self:GetText("Root/GrpDialog/GrpTop/GrpText/TitleText")
  self.mImage_Icon = self:GetImage("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpTacticSkillIcon/GrpIcon/ImgIcon")
  self.mText_SkillName = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpText/Text_Name")
  self.mText_OilCostName = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpText/GrpCost/TextName")
  self.mText_OilCostNum = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpText/GrpCost/Text_Num")
  self.mText_UseTimesName = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpText/GrpTime/TextName")
  self.mText_UstTimesNum = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpText/GrpTime/Text_Num")
  self.mText_LevelNum = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillInfo/GrpLevel/Text_Level")
  self.mBtn_Info = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpSkillInfo/BtnInfo"))
  self.mText_SkillDes = self:GetText("Root/GrpDialog/GrpCenter/GrpSkillDescription/GrpSkillDescription/Viewport/Content/Text_Description")
  self.mTrans_SkillDetail = self:GetRectTransform("Root/GrpDialog/Trans_GrpSkillDetails")
  self.mBtn_DetailClose = self:GetButton("Root/GrpDialog/Trans_GrpSkillDetails/Btn_Close")
  self.mBtn_CloseDetailInfo = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/Trans_GrpSkillDetails/BtnInfo"))
  self.mText_DetailSkillDes = self:GetText("Root/GrpDialog/Trans_GrpSkillDetails/GrpAllSkillDescription/GrpDescribe/Viewport/Content/Text_Level1")
  self.mTrans_DetailSkillLeveDes = self:GetRectTransform("Root/GrpDialog/Trans_GrpSkillDetails/GrpAllSkillDescription/GrpDescribe/Viewport/Content/GrpLevelDescription")
  self.mLayoutlist = {}
  self.mTrans_layout1 = self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpSkillDescription/GrpSkillDiagram/Img_SkillDiagram_9x9")
  self.mTrans_layout2 = self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpSkillDescription/GrpSkillDiagram/Img_SkillDiagram_17x17")
  self.mTrans_layout3 = self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpSkillDescription/GrpSkillDiagram/Img_SkillDiagram_21x21")
  table.insert(self.mLayoutlist, getcomponent(self.mTrans_layout1, typeof(CS.GridLayout)))
  table.insert(self.mLayoutlist, getcomponent(self.mTrans_layout2, typeof(CS.GridLayout)))
  table.insert(self.mLayoutlist, getcomponent(self.mTrans_layout3, typeof(CS.GridLayout)))
end

function UIUAVSkillInfoPanelView:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
end