DormGlobal = {}
DormGlobal.ScreenPanelGunId = 0
DormGlobal.Direction = {
  None = 0,
  Left = 1,
  Right = 2,
  Top = 3,
  Bottom = 4,
  Forward = 5,
  Back = 6
}
DormGlobal.IsShowUI = true
DormGlobal.IsSkinClose = false
DormGlobal.IsSkinOpen = false
DormGlobal.IsResetOrientation = false
DormGlobal.jumptomainpanel = false
DormGlobal.IsChangeOrientation = false

function DormGlobal.ChangeOrientation()
  CS.UnityEngine.Screen.orientation = CS.UnityEngine.ScreenOrientation.AutoRotation
  CS.UnityEngine.Screen.autorotateToLandscapeRight = true
  CS.UnityEngine.Screen.autorotateToLandscapeLeft = true
  CS.UnityEngine.Screen.autorotateToPortrait = true
  CS.UnityEngine.Screen.autorotateToPortraitUpsideDown = true
  DormGlobal.IsResetOrientation = false
  DormGlobal.IsChangeOrientation = true
end
