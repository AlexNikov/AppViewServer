// Generated from AppViewDashboardBlueprint.m — do not edit by hand.
import Foundation

public final class AppViewDashboardBlueprint: NSObject {

    private struct AttrInfo {
        var className: String?
        var fullTitle: String?
        var briefTitle: String?
        var getter: AppViewAttributeGetter?
        var setterString: String?
        var typeIfObj: AppViewAttrType?
        var enumList: String?
        var patch: Bool?
        var hideIfNil: Bool?
        var osVersion: Int?
    }

    private static let allGroupIDs: [AppViewAttrGroupIdentifier] = [
        AppViewAttrGroup_Class,
        AppViewAttrGroup_Accessibility,
        AppViewAttrGroup_Relation,
        AppViewAttrGroup_Layout,
        AppViewAttrGroup_AutoLayout,
        AppViewAttrGroup_ViewLayer,
        AppViewAttrGroup_UIStackView,
        AppViewAttrGroup_UIVisualEffectView,
        AppViewAttrGroup_UIImageView,
        AppViewAttrGroup_UILabel,
        AppViewAttrGroup_UIControl,
        AppViewAttrGroup_UIButton,
        AppViewAttrGroup_UIScrollView,
        AppViewAttrGroup_UITableView,
        AppViewAttrGroup_UITextView,
        AppViewAttrGroup_UITextField,
    ]

    private static let sectionsByGroup: [AppViewAttrGroupIdentifier: [AppViewAttrSectionIdentifier]] = [
        AppViewAttrGroup_Class: [AppViewAttrSec_Class_Class],
        AppViewAttrGroup_Accessibility: [
            AppViewAttrSec_Accessibility_Identifier,
            AppViewAttrSec_Accessibility_Label,
            AppViewAttrSec_Accessibility_Value,
            AppViewAttrSec_Accessibility_Hint,
            AppViewAttrSec_Accessibility_Flags,
            AppViewAttrSec_Accessibility_Traits,
        ],
        AppViewAttrGroup_Relation: [AppViewAttrSec_Relation_Relation],
        AppViewAttrGroup_Layout: [AppViewAttrSec_Layout_Frame, AppViewAttrSec_Layout_Bounds, AppViewAttrSec_Layout_SafeArea, AppViewAttrSec_Layout_Position, AppViewAttrSec_Layout_AnchorPoint],
        AppViewAttrGroup_AutoLayout: [AppViewAttrSec_AutoLayout_Issues, AppViewAttrSec_AutoLayout_Constraints, AppViewAttrSec_AutoLayout_InstalledConstraints, AppViewAttrSec_AutoLayout_IntrinsicSize, AppViewAttrSec_AutoLayout_Hugging, AppViewAttrSec_AutoLayout_Resistance],
        AppViewAttrGroup_ViewLayer: [AppViewAttrSec_ViewLayer_Visibility, AppViewAttrSec_ViewLayer_InterationAndMasks, AppViewAttrSec_ViewLayer_BgColor, AppViewAttrSec_ViewLayer_Border, AppViewAttrSec_ViewLayer_Corner, AppViewAttrSec_ViewLayer_Shadow, AppViewAttrSec_ViewLayer_ContentMode, AppViewAttrSec_ViewLayer_TintColor, AppViewAttrSec_ViewLayer_Tag],
        AppViewAttrGroup_UIStackView: [AppViewAttrSec_UIStackView_Axis, AppViewAttrSec_UIStackView_Distribution, AppViewAttrSec_UIStackView_Alignment, AppViewAttrSec_UIStackView_Spacing],
        AppViewAttrGroup_UIVisualEffectView: [AppViewAttrSec_UIVisualEffectView_Style, AppViewAttrSec_UIVisualEffectView_QMUIForegroundColor],
        AppViewAttrGroup_UIImageView: [AppViewAttrSec_UIImageView_Name, AppViewAttrSec_UIImageView_Open],
        AppViewAttrGroup_UILabel: [AppViewAttrSec_UILabel_Text, AppViewAttrSec_UILabel_Font, AppViewAttrSec_UILabel_NumberOfLines, AppViewAttrSec_UILabel_TextColor, AppViewAttrSec_UILabel_BreakMode, AppViewAttrSec_UILabel_Alignment, AppViewAttrSec_UILabel_CanAdjustFont],
        AppViewAttrGroup_UIControl: [AppViewAttrSec_UIControl_EnabledSelected, AppViewAttrSec_UIControl_QMUIOutsideEdge, AppViewAttrSec_UIControl_VerAlignment, AppViewAttrSec_UIControl_HorAlignment],
        AppViewAttrGroup_UIButton: [AppViewAttrSec_UIButton_ContentInsets, AppViewAttrSec_UIButton_TitleInsets, AppViewAttrSec_UIButton_ImageInsets],
        AppViewAttrGroup_UIScrollView: [AppViewAttrSec_UIScrollView_ContentInset, AppViewAttrSec_UIScrollView_AdjustedInset, AppViewAttrSec_UIScrollView_QMUIInitialInset, AppViewAttrSec_UIScrollView_IndicatorInset, AppViewAttrSec_UIScrollView_Offset, AppViewAttrSec_UIScrollView_ContentSize, AppViewAttrSec_UIScrollView_Behavior, AppViewAttrSec_UIScrollView_ShowsIndicator, AppViewAttrSec_UIScrollView_Bounce, AppViewAttrSec_UIScrollView_ScrollPaging, AppViewAttrSec_UIScrollView_ContentTouches, AppViewAttrSec_UIScrollView_Zoom],
        AppViewAttrGroup_UITableView: [AppViewAttrSec_UITableView_Style, AppViewAttrSec_UITableView_SectionsNumber, AppViewAttrSec_UITableView_RowsNumber, AppViewAttrSec_UITableView_SeparatorStyle, AppViewAttrSec_UITableView_SeparatorColor, AppViewAttrSec_UITableView_SeparatorInset],
        AppViewAttrGroup_UITextView: [AppViewAttrSec_UITextView_Basic, AppViewAttrSec_UITextView_Text, AppViewAttrSec_UITextView_Font, AppViewAttrSec_UITextView_TextColor, AppViewAttrSec_UITextView_Alignment, AppViewAttrSec_UITextView_ContainerInset],
        AppViewAttrGroup_UITextField: [AppViewAttrSec_UITextField_Text, AppViewAttrSec_UITextField_Placeholder, AppViewAttrSec_UITextField_Font, AppViewAttrSec_UITextField_TextColor, AppViewAttrSec_UITextField_Alignment, AppViewAttrSec_UITextField_Clears, AppViewAttrSec_UITextField_CanAdjustFont, AppViewAttrSec_UITextField_ClearButtonMode],
    ]

    private static let attrsBySection: [AppViewAttrSectionIdentifier: [AppViewAttrIdentifier]] = [
        AppViewAttrSec_Class_Class: [AppViewAttr_Class_Class_Class],
        AppViewAttrSec_Accessibility_Identifier: [AppViewAttr_Accessibility_Identifier],
        AppViewAttrSec_Accessibility_Label: [AppViewAttr_Accessibility_Label],
        AppViewAttrSec_Accessibility_Value: [AppViewAttr_Accessibility_Value],
        AppViewAttrSec_Accessibility_Hint: [AppViewAttr_Accessibility_Hint],
        AppViewAttrSec_Accessibility_Flags: [
            AppViewAttr_Accessibility_IsElement,
            AppViewAttr_Accessibility_ElementsHidden,
            AppViewAttr_Accessibility_ViewIsModal,
        ],
        AppViewAttrSec_Accessibility_Traits: [AppViewAttr_Accessibility_Traits],
        AppViewAttrSec_Relation_Relation: [AppViewAttr_Relation_Relation_Relation],
        AppViewAttrSec_Layout_Frame: [AppViewAttr_Layout_Frame_Frame],
        AppViewAttrSec_Layout_Bounds: [AppViewAttr_Layout_Bounds_Bounds],
        AppViewAttrSec_Layout_SafeArea: [AppViewAttr_Layout_SafeArea_SafeArea],
        AppViewAttrSec_Layout_Position: [AppViewAttr_Layout_Position_Position],
        AppViewAttrSec_Layout_AnchorPoint: [AppViewAttr_Layout_AnchorPoint_AnchorPoint],
        AppViewAttrSec_AutoLayout_Hugging: [AppViewAttr_AutoLayout_Hugging_Hor, AppViewAttr_AutoLayout_Hugging_Ver],
        AppViewAttrSec_AutoLayout_Resistance: [AppViewAttr_AutoLayout_Resistance_Hor, AppViewAttr_AutoLayout_Resistance_Ver],
        AppViewAttrSec_AutoLayout_Constraints: [AppViewAttr_AutoLayout_Constraints_Constraints],
        AppViewAttrSec_AutoLayout_InstalledConstraints: [AppViewAttr_AutoLayout_InstalledConstraints_Constraints],
        AppViewAttrSec_AutoLayout_Issues: [AppViewAttr_AutoLayout_Issues_Issues],
        AppViewAttrSec_AutoLayout_IntrinsicSize: [AppViewAttr_AutoLayout_IntrinsicSize_Size],
        AppViewAttrSec_ViewLayer_Visibility: [AppViewAttr_ViewLayer_Visibility_Hidden, AppViewAttr_ViewLayer_Visibility_Opacity],
        AppViewAttrSec_ViewLayer_InterationAndMasks: [AppViewAttr_ViewLayer_InterationAndMasks_Interaction, AppViewAttr_ViewLayer_InterationAndMasks_MasksToBounds],
        AppViewAttrSec_ViewLayer_Corner: [AppViewAttr_ViewLayer_Corner_Radius],
        AppViewAttrSec_ViewLayer_BgColor: [AppViewAttr_ViewLayer_BgColor_BgColor],
        AppViewAttrSec_ViewLayer_Border: [AppViewAttr_ViewLayer_Border_Color, AppViewAttr_ViewLayer_Border_Width],
        AppViewAttrSec_ViewLayer_Shadow: [AppViewAttr_ViewLayer_Shadow_Color, AppViewAttr_ViewLayer_Shadow_Opacity, AppViewAttr_ViewLayer_Shadow_Radius, AppViewAttr_ViewLayer_Shadow_OffsetW, AppViewAttr_ViewLayer_Shadow_OffsetH],
        AppViewAttrSec_ViewLayer_ContentMode: [AppViewAttr_ViewLayer_ContentMode_Mode],
        AppViewAttrSec_ViewLayer_TintColor: [AppViewAttr_ViewLayer_TintColor_Color, AppViewAttr_ViewLayer_TintColor_Mode],
        AppViewAttrSec_ViewLayer_Tag: [AppViewAttr_ViewLayer_Tag_Tag],
        AppViewAttrSec_UIStackView_Axis: [AppViewAttr_UIStackView_Axis_Axis],
        AppViewAttrSec_UIStackView_Distribution: [AppViewAttr_UIStackView_Distribution_Distribution],
        AppViewAttrSec_UIStackView_Alignment: [AppViewAttr_UIStackView_Alignment_Alignment],
        AppViewAttrSec_UIStackView_Spacing: [AppViewAttr_UIStackView_Spacing_Spacing],
        AppViewAttrSec_UIVisualEffectView_Style: [AppViewAttr_UIVisualEffectView_Style_Style],
        AppViewAttrSec_UIVisualEffectView_QMUIForegroundColor: [AppViewAttr_UIVisualEffectView_QMUIForegroundColor_Color],
        AppViewAttrSec_UIImageView_Name: [AppViewAttr_UIImageView_Name_Name],
        AppViewAttrSec_UIImageView_Open: [AppViewAttr_UIImageView_Open_Open],
        AppViewAttrSec_UILabel_Font: [AppViewAttr_UILabel_Font_Name, AppViewAttr_UILabel_Font_Size],
        AppViewAttrSec_UILabel_NumberOfLines: [AppViewAttr_UILabel_NumberOfLines_NumberOfLines],
        AppViewAttrSec_UILabel_Text: [AppViewAttr_UILabel_Text_Text],
        AppViewAttrSec_UILabel_TextColor: [AppViewAttr_UILabel_TextColor_Color],
        AppViewAttrSec_UILabel_BreakMode: [AppViewAttr_UILabel_BreakMode_Mode],
        AppViewAttrSec_UILabel_Alignment: [AppViewAttr_UILabel_Alignment_Alignment],
        AppViewAttrSec_UILabel_CanAdjustFont: [AppViewAttr_UILabel_CanAdjustFont_CanAdjustFont],
        AppViewAttrSec_UIControl_EnabledSelected: [AppViewAttr_UIControl_EnabledSelected_Enabled, AppViewAttr_UIControl_EnabledSelected_Selected],
        AppViewAttrSec_UIControl_QMUIOutsideEdge: [AppViewAttr_UIControl_QMUIOutsideEdge_Edge],
        AppViewAttrSec_UIControl_VerAlignment: [AppViewAttr_UIControl_VerAlignment_Alignment],
        AppViewAttrSec_UIControl_HorAlignment: [AppViewAttr_UIControl_HorAlignment_Alignment],
        AppViewAttrSec_UIButton_ContentInsets: [AppViewAttr_UIButton_ContentInsets_Insets],
        AppViewAttrSec_UIButton_TitleInsets: [AppViewAttr_UIButton_TitleInsets_Insets],
        AppViewAttrSec_UIButton_ImageInsets: [AppViewAttr_UIButton_ImageInsets_Insets],
        AppViewAttrSec_UIScrollView_ContentInset: [AppViewAttr_UIScrollView_ContentInset_Inset],
        AppViewAttrSec_UIScrollView_AdjustedInset: [AppViewAttr_UIScrollView_AdjustedInset_Inset],
        AppViewAttrSec_UIScrollView_QMUIInitialInset: [AppViewAttr_UIScrollView_QMUIInitialInset_Inset],
        AppViewAttrSec_UIScrollView_IndicatorInset: [AppViewAttr_UIScrollView_IndicatorInset_Inset],
        AppViewAttrSec_UIScrollView_Offset: [AppViewAttr_UIScrollView_Offset_Offset],
        AppViewAttrSec_UIScrollView_ContentSize: [AppViewAttr_UIScrollView_ContentSize_Size],
        AppViewAttrSec_UIScrollView_Behavior: [AppViewAttr_UIScrollView_Behavior_Behavior],
        AppViewAttrSec_UIScrollView_ShowsIndicator: [AppViewAttr_UIScrollView_ShowsIndicator_Hor, AppViewAttr_UIScrollView_ShowsIndicator_Ver],
        AppViewAttrSec_UIScrollView_Bounce: [AppViewAttr_UIScrollView_Bounce_Hor, AppViewAttr_UIScrollView_Bounce_Ver],
        AppViewAttrSec_UIScrollView_ScrollPaging: [AppViewAttr_UIScrollView_ScrollPaging_ScrollEnabled, AppViewAttr_UIScrollView_ScrollPaging_PagingEnabled],
        AppViewAttrSec_UIScrollView_ContentTouches: [AppViewAttr_UIScrollView_ContentTouches_Delay, AppViewAttr_UIScrollView_ContentTouches_CanCancel],
        AppViewAttrSec_UIScrollView_Zoom: [AppViewAttr_UIScrollView_Zoom_Bounce, AppViewAttr_UIScrollView_Zoom_Scale, AppViewAttr_UIScrollView_Zoom_MinScale, AppViewAttr_UIScrollView_Zoom_MaxScale],
        AppViewAttrSec_UITableView_Style: [AppViewAttr_UITableView_Style_Style],
        AppViewAttrSec_UITableView_SectionsNumber: [AppViewAttr_UITableView_SectionsNumber_Number],
        AppViewAttrSec_UITableView_RowsNumber: [AppViewAttr_UITableView_RowsNumber_Number],
        AppViewAttrSec_UITableView_SeparatorInset: [AppViewAttr_UITableView_SeparatorInset_Inset],
        AppViewAttrSec_UITableView_SeparatorColor: [AppViewAttr_UITableView_SeparatorColor_Color],
        AppViewAttrSec_UITableView_SeparatorStyle: [AppViewAttr_UITableView_SeparatorStyle_Style],
        AppViewAttrSec_UITextView_Basic: [AppViewAttr_UITextView_Basic_Editable, AppViewAttr_UITextView_Basic_Selectable],
        AppViewAttrSec_UITextView_Text: [AppViewAttr_UITextView_Text_Text],
        AppViewAttrSec_UITextView_Font: [AppViewAttr_UITextView_Font_Name, AppViewAttr_UITextView_Font_Size],
        AppViewAttrSec_UITextView_TextColor: [AppViewAttr_UITextView_TextColor_Color],
        AppViewAttrSec_UITextView_Alignment: [AppViewAttr_UITextView_Alignment_Alignment],
        AppViewAttrSec_UITextView_ContainerInset: [AppViewAttr_UITextView_ContainerInset_Inset],
        AppViewAttrSec_UITextField_Text: [AppViewAttr_UITextField_Text_Text],
        AppViewAttrSec_UITextField_Placeholder: [AppViewAttr_UITextField_Placeholder_Placeholder],
        AppViewAttrSec_UITextField_Font: [AppViewAttr_UITextField_Font_Name, AppViewAttr_UITextField_Font_Size],
        AppViewAttrSec_UITextField_TextColor: [AppViewAttr_UITextField_TextColor_Color],
        AppViewAttrSec_UITextField_Alignment: [AppViewAttr_UITextField_Alignment_Alignment],
        AppViewAttrSec_UITextField_Clears: [AppViewAttr_UITextField_Clears_ClearsOnBeginEditing, AppViewAttr_UITextField_Clears_ClearsOnInsertion],
        AppViewAttrSec_UITextField_CanAdjustFont: [AppViewAttr_UITextField_CanAdjustFont_CanAdjustFont, AppViewAttr_UITextField_CanAdjustFont_MinSize],
        AppViewAttrSec_UITextField_ClearButtonMode: [AppViewAttr_UITextField_ClearButtonMode_Mode],
    ]

    private static let groupTitles: [AppViewAttrGroupIdentifier: String] = [
        AppViewAttrGroup_Class: "Class",
        AppViewAttrGroup_Accessibility: "Accessibility",
        AppViewAttrGroup_Relation: "Relation",
        AppViewAttrGroup_Layout: "Layout",
        AppViewAttrGroup_AutoLayout: "AutoLayout",
        AppViewAttrGroup_ViewLayer: "CALayer / UIView",
        AppViewAttrGroup_UIImageView: "UIImageView",
        AppViewAttrGroup_UILabel: "UILabel",
        AppViewAttrGroup_UIControl: "UIControl",
        AppViewAttrGroup_UIButton: "UIButton",
        AppViewAttrGroup_UIScrollView: "UIScrollView",
        AppViewAttrGroup_UITableView: "UITableView",
        AppViewAttrGroup_UITextView: "UITextView",
        AppViewAttrGroup_UITextField: "UITextField",
        AppViewAttrGroup_UIVisualEffectView: "UIVisualEffectView",
        AppViewAttrGroup_UIStackView: "UIStackView",
    ]

    private static let sectionTitles: [AppViewAttrSectionIdentifier: String] = [
        AppViewAttrSec_Layout_Frame: "Frame",
        AppViewAttrSec_Layout_Bounds: "Bounds",
        AppViewAttrSec_Layout_SafeArea: "SafeArea",
        AppViewAttrSec_Layout_Position: "Position",
        AppViewAttrSec_Layout_AnchorPoint: "AnchorPoint",
        AppViewAttrSec_AutoLayout_Issues: "Layout Issues",
        AppViewAttrSec_AutoLayout_Constraints: "Constraints",
        AppViewAttrSec_AutoLayout_InstalledConstraints: "Installed here",
        AppViewAttrSec_AutoLayout_Hugging: "HuggingPriority",
        AppViewAttrSec_AutoLayout_Resistance: "ResistancePriority",
        AppViewAttrSec_AutoLayout_IntrinsicSize: "IntrinsicSize",
        AppViewAttrSec_ViewLayer_Corner: "CornerRadius",
        AppViewAttrSec_ViewLayer_BgColor: "BackgroundColor",
        AppViewAttrSec_ViewLayer_Border: "Border",
        AppViewAttrSec_ViewLayer_Shadow: "Shadow",
        AppViewAttrSec_ViewLayer_ContentMode: "ContentMode",
        AppViewAttrSec_ViewLayer_TintColor: "TintColor",
        AppViewAttrSec_ViewLayer_Tag: "Tag",
        AppViewAttrSec_UIStackView_Axis: "Axis",
        AppViewAttrSec_UIStackView_Distribution: "Distribution",
        AppViewAttrSec_UIStackView_Alignment: "Alignment",
        AppViewAttrSec_UIVisualEffectView_Style: "Style",
        AppViewAttrSec_UIVisualEffectView_QMUIForegroundColor: "ForegroundColor",
        AppViewAttrSec_UIImageView_Name: "ImageName",
        AppViewAttrSec_UILabel_TextColor: "TextColor",
        AppViewAttrSec_UITextView_TextColor: "TextColor",
        AppViewAttrSec_UITextField_TextColor: "TextColor",
        AppViewAttrSec_UILabel_BreakMode: "LineBreakMode",
        AppViewAttrSec_UILabel_NumberOfLines: "NumberOfLines",
        AppViewAttrSec_Accessibility_Identifier: "Identifier",
        AppViewAttrSec_Accessibility_Label: "Label",
        AppViewAttrSec_Accessibility_Value: "Value",
        AppViewAttrSec_Accessibility_Hint: "Hint",
        AppViewAttrSec_Accessibility_Traits: "Traits",
        AppViewAttrSec_UILabel_Text: "Text",
        AppViewAttrSec_UITextView_Text: "Text",
        AppViewAttrSec_UITextField_Text: "Text",
        AppViewAttrSec_UITextField_Placeholder: "Placeholder",
        AppViewAttrSec_UILabel_Alignment: "TextAlignment",
        AppViewAttrSec_UITextView_Alignment: "TextAlignment",
        AppViewAttrSec_UITextField_Alignment: "TextAlignment",
        AppViewAttrSec_UIControl_HorAlignment: "HorizontalAlignment",
        AppViewAttrSec_UIControl_VerAlignment: "VerticalAlignment",
        AppViewAttrSec_UIControl_QMUIOutsideEdge: "QMUI_outsideEdge",
        AppViewAttrSec_UIButton_ContentInsets: "ContentInsets",
        AppViewAttrSec_UIButton_TitleInsets: "TitleInsets",
        AppViewAttrSec_UIButton_ImageInsets: "ImageInsets",
        AppViewAttrSec_UIScrollView_QMUIInitialInset: "QMUI_initialContentInset",
        AppViewAttrSec_UIScrollView_ContentInset: "ContentInset",
        AppViewAttrSec_UIScrollView_AdjustedInset: "AdjustedContentInset",
        AppViewAttrSec_UIScrollView_IndicatorInset: "ScrollIndicatorInsets",
        AppViewAttrSec_UIScrollView_Offset: "ContentOffset",
        AppViewAttrSec_UIScrollView_ContentSize: "ContentSize",
        AppViewAttrSec_UIScrollView_Behavior: "InsetAdjustmentBehavior",
        AppViewAttrSec_UIScrollView_ShowsIndicator: "ShowsScrollIndicator",
        AppViewAttrSec_UIScrollView_Bounce: "AlwaysBounce",
        AppViewAttrSec_UIScrollView_Zoom: "Zoom",
        AppViewAttrSec_UITableView_Style: "Style",
        AppViewAttrSec_UITableView_SectionsNumber: "NumberOfSections",
        AppViewAttrSec_UITableView_RowsNumber: "NumberOfRows",
        AppViewAttrSec_UITableView_SeparatorColor: "SeparatorColor",
        AppViewAttrSec_UITableView_SeparatorInset: "SeparatorInset",
        AppViewAttrSec_UITableView_SeparatorStyle: "SeparatorStyle",
        AppViewAttrSec_UILabel_Font: "Font",
        AppViewAttrSec_UITextField_Font: "Font",
        AppViewAttrSec_UITextView_Font: "Font",
        AppViewAttrSec_UITextView_ContainerInset: "ContainerInset",
        AppViewAttrSec_UITextField_ClearButtonMode: "ClearButtonMode",
    ]

    private static let attrInfos: [AppViewAttrIdentifier: AttrInfo] = {
        var dict: [AppViewAttrIdentifier: AttrInfo] = [:]
        dict[AppViewAttr_Class_Class_Class] = AttrInfo(
            className: "CALayer",
            getter: .avs_relatedClassChainList,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj
        )
        dict[AppViewAttr_Accessibility_Identifier] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityIdentifier",
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_Accessibility_Label] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityLabel",
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_Accessibility_Value] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityValue",
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_Accessibility_Hint] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityHint",
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_Accessibility_IsElement] = AttrInfo(
            className: "UIView",
            fullTitle: "IsAccessibilityElement",
            briefTitle: "IsElement",
            getter: .isAccessibilityElement,
            setterString: "",
            patch: false
        )
        dict[AppViewAttr_Accessibility_Traits] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityTraits",
            getter: .avs_accessibilityTraitsDescription,
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            hideIfNil: true
        )
        dict[AppViewAttr_Accessibility_ElementsHidden] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityElementsHidden",
            briefTitle: "ElementsHidden",
            setterString: "",
            patch: false
        )
        dict[AppViewAttr_Accessibility_ViewIsModal] = AttrInfo(
            className: "UIView",
            fullTitle: "AccessibilityViewIsModal",
            briefTitle: "ViewIsModal",
            setterString: "",
            patch: false
        )
        dict[AppViewAttr_Relation_Relation_Relation] = AttrInfo(
            className: "CALayer",
            getter: .avs_selfRelation,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj,
            hideIfNil: true
        )
        dict[AppViewAttr_Layout_Frame_Frame] = AttrInfo(
            className: "CALayer",
            fullTitle: "Frame",
            patch: true
        )
        dict[AppViewAttr_Layout_Bounds_Bounds] = AttrInfo(
            className: "CALayer",
            fullTitle: "Bounds",
            patch: true
        )
        dict[AppViewAttr_Layout_SafeArea_SafeArea] = AttrInfo(
            className: "UIView",
            fullTitle: "SafeAreaInsets",
            setterString: "",
            osVersion: 11
        )
        dict[AppViewAttr_Layout_Position_Position] = AttrInfo(
            className: "CALayer",
            fullTitle: "Position",
            patch: true
        )
        dict[AppViewAttr_Layout_AnchorPoint_AnchorPoint] = AttrInfo(
            className: "CALayer",
            fullTitle: "AnchorPoint",
            patch: true
        )
        dict[AppViewAttr_AutoLayout_Hugging_Hor] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentHuggingPriority(Horizontal)",
            briefTitle: "H",
            getter: .avs_horizontalContentHuggingPriority,
            setterString: "setAvs_horizontalContentHuggingPriority:",
            patch: true
        )
        dict[AppViewAttr_AutoLayout_Hugging_Ver] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentHuggingPriority(Vertical)",
            briefTitle: "V",
            getter: .avs_verticalContentHuggingPriority,
            setterString: "setAvs_verticalContentHuggingPriority:",
            patch: true
        )
        dict[AppViewAttr_AutoLayout_Resistance_Hor] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentCompressionResistancePriority(Horizontal)",
            briefTitle: "H",
            getter: .avs_horizontalContentCompressionResistancePriority,
            setterString: "setAvs_horizontalContentCompressionResistancePriority:",
            patch: true
        )
        dict[AppViewAttr_AutoLayout_Resistance_Ver] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentCompressionResistancePriority(Vertical)",
            briefTitle: "V",
            getter: .avs_verticalContentCompressionResistancePriority,
            setterString: "setAvs_verticalContentCompressionResistancePriority:",
            patch: true
        )
        dict[AppViewAttr_AutoLayout_Constraints_Constraints] = AttrInfo(
            className: "UIView",
            getter: .avs_constraints,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj,
            hideIfNil: true
        )
        dict[AppViewAttr_AutoLayout_InstalledConstraints_Constraints] = AttrInfo(
            className: "UIView",
            getter: .avs_installedConstraints,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj,
            hideIfNil: true
        )
        dict[AppViewAttr_AutoLayout_Issues_Issues] = AttrInfo(
            className: "UIView",
            getter: .avs_layoutIssues,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj,
            hideIfNil: true
        )
        dict[AppViewAttr_AutoLayout_IntrinsicSize_Size] = AttrInfo(
            className: "UIView",
            fullTitle: "IntrinsicContentSize",
            setterString: ""
        )
        dict[AppViewAttr_ViewLayer_Visibility_Hidden] = AttrInfo(
            className: "CALayer",
            fullTitle: "Hidden",
            getter: .isHidden,
            patch: false
        )
        dict[AppViewAttr_ViewLayer_Visibility_Opacity] = AttrInfo(
            className: "CALayer",
            fullTitle: "Opacity / Alpha",
            getter: .opacity,
            setterString: "setOpacity:",
            patch: false
        )
        dict[AppViewAttr_ViewLayer_InterationAndMasks_Interaction] = AttrInfo(
            className: "UIView",
            fullTitle: "UserInteractionEnabled",
            getter: .isUserInteractionEnabled,
            patch: false
        )
        dict[AppViewAttr_ViewLayer_InterationAndMasks_MasksToBounds] = AttrInfo(
            className: "CALayer",
            fullTitle: "MasksToBounds / ClipsToBounds",
            briefTitle: "MasksToBounds",
            getter: .masksToBounds,
            setterString: "setMasksToBounds:",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Corner_Radius] = AttrInfo(
            className: "CALayer",
            fullTitle: "CornerRadius",
            briefTitle: "",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_BgColor_BgColor] = AttrInfo(
            className: "CALayer",
            fullTitle: "BackgroundColor",
            getter: .avs_backgroundColor,
            setterString: "setAvs_backgroundColor:",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Border_Color] = AttrInfo(
            className: "CALayer",
            fullTitle: "BorderColor",
            getter: .avs_borderColor,
            setterString: "setAvs_borderColor:",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Border_Width] = AttrInfo(
            className: "CALayer",
            fullTitle: "BorderWidth",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Shadow_Color] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowColor",
            getter: .avs_shadowColor,
            setterString: "setAvs_shadowColor:",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Shadow_Opacity] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowOpacity",
            briefTitle: "Opacity",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Shadow_Radius] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowRadius",
            briefTitle: "Radius",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Shadow_OffsetW] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowOffsetWidth",
            briefTitle: "OffsetW",
            getter: .avs_shadowOffsetWidth,
            setterString: "setAvs_shadowOffsetWidth:",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Shadow_OffsetH] = AttrInfo(
            className: "CALayer",
            fullTitle: "ShadowOffsetHeight",
            briefTitle: "OffsetH",
            getter: .avs_shadowOffsetHeight,
            setterString: "setAvs_shadowOffsetHeight:",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_ContentMode_Mode] = AttrInfo(
            className: "UIView",
            fullTitle: "ContentMode",
            enumList: "UIViewContentMode",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_TintColor_Color] = AttrInfo(
            className: "UIView",
            fullTitle: "TintColor",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_ViewLayer_TintColor_Mode] = AttrInfo(
            className: "UIView",
            fullTitle: "TintAdjustmentMode",
            enumList: "UIViewTintAdjustmentMode",
            patch: true
        )
        dict[AppViewAttr_ViewLayer_Tag_Tag] = AttrInfo(
            className: "UIView",
            fullTitle: "Tag",
            briefTitle: "",
            patch: false
        )
        dict[AppViewAttr_UIStackView_Axis_Axis] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Axis",
            enumList: "UILayoutConstraintAxis",
            patch: true
        )
        dict[AppViewAttr_UIStackView_Distribution_Distribution] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Distribution",
            enumList: "UIStackViewDistribution",
            patch: true
        )
        dict[AppViewAttr_UIStackView_Alignment_Alignment] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Alignment",
            enumList: "UIStackViewAlignment",
            patch: true
        )
        dict[AppViewAttr_UIStackView_Spacing_Spacing] = AttrInfo(
            className: "UIStackView",
            fullTitle: "Spacing",
            patch: true
        )
        dict[AppViewAttr_UIVisualEffectView_Style_Style] = AttrInfo(
            className: "UIVisualEffectView",
            getter: .avs_blurEffectStyleNumber,
            setterString: "setAvs_blurEffectStyleNumber:",
            typeIfObj: AppViewAttrType.customObj,
            enumList: "UIBlurEffectStyle",
            patch: true,
            hideIfNil: true
        )
        dict[AppViewAttr_UIVisualEffectView_QMUIForegroundColor_Color] = AttrInfo(
            className: "QMUIVisualEffectView",
            fullTitle: "ForegroundColor",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_UIImageView_Name_Name] = AttrInfo(
            className: "UIImageView",
            fullTitle: "ImageName",
            getter: .avs_imageSourceName,
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            hideIfNil: true
        )
        dict[AppViewAttr_UIImageView_Open_Open] = AttrInfo(
            className: "UIImageView",
            getter: .avs_imageViewOidIfHasImage,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj,
            hideIfNil: true
        )
        dict[AppViewAttr_UILabel_Text_Text] = AttrInfo(
            className: "UILabel",
            fullTitle: "Text",
            typeIfObj: AppViewAttrType.NSString,
            patch: true
        )
        dict[AppViewAttr_UILabel_NumberOfLines_NumberOfLines] = AttrInfo(
            className: "UILabel",
            fullTitle: "NumberOfLines",
            briefTitle: "",
            patch: true
        )
        dict[AppViewAttr_UILabel_Font_Size] = AttrInfo(
            className: "UILabel",
            fullTitle: "FontSize",
            briefTitle: "FontSize",
            getter: .avs_fontSize,
            setterString: "setAvs_fontSize:",
            patch: true
        )
        dict[AppViewAttr_UILabel_Font_Name] = AttrInfo(
            className: "UILabel",
            fullTitle: "FontName",
            getter: .avs_fontName,
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_UILabel_TextColor_Color] = AttrInfo(
            className: "UILabel",
            fullTitle: "TextColor",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_UILabel_Alignment_Alignment] = AttrInfo(
            className: "UILabel",
            fullTitle: "TextAlignment",
            enumList: "NSTextAlignment",
            patch: true
        )
        dict[AppViewAttr_UILabel_BreakMode_Mode] = AttrInfo(
            className: "UILabel",
            fullTitle: "LineBreakMode",
            enumList: "NSLineBreakMode",
            patch: true
        )
        dict[AppViewAttr_UILabel_CanAdjustFont_CanAdjustFont] = AttrInfo(
            className: "UILabel",
            fullTitle: "AdjustsFontSizeToFitWidth",
            patch: true
        )
        dict[AppViewAttr_UIControl_EnabledSelected_Enabled] = AttrInfo(
            className: "UIControl",
            fullTitle: "Enabled",
            getter: .isEnabled,
            patch: false
        )
        dict[AppViewAttr_UIControl_EnabledSelected_Selected] = AttrInfo(
            className: "UIControl",
            fullTitle: "Selected",
            getter: .isSelected,
            patch: true
        )
        dict[AppViewAttr_UIControl_VerAlignment_Alignment] = AttrInfo(
            className: "UIControl",
            fullTitle: "ContentVerticalAlignment",
            enumList: "UIControlContentVerticalAlignment",
            patch: true
        )
        dict[AppViewAttr_UIControl_HorAlignment_Alignment] = AttrInfo(
            className: "UIControl",
            fullTitle: "ContentHorizontalAlignment",
            enumList: "UIControlContentHorizontalAlignment",
            patch: true
        )
        dict[AppViewAttr_UIControl_QMUIOutsideEdge_Edge] = AttrInfo(
            className: "UIControl",
            fullTitle: "qmui_outsideEdge"
        )
        dict[AppViewAttr_UIButton_ContentInsets_Insets] = AttrInfo(
            className: "UIButton",
            fullTitle: "ContentEdgeInsets",
            patch: true
        )
        dict[AppViewAttr_UIButton_TitleInsets_Insets] = AttrInfo(
            className: "UIButton",
            fullTitle: "TitleEdgeInsets",
            patch: true
        )
        dict[AppViewAttr_UIButton_ImageInsets_Insets] = AttrInfo(
            className: "UIButton",
            fullTitle: "ImageEdgeInsets",
            patch: true
        )
        dict[AppViewAttr_UIScrollView_Offset_Offset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentOffset",
            patch: true
        )
        dict[AppViewAttr_UIScrollView_ContentSize_Size] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentSize",
            patch: true
        )
        dict[AppViewAttr_UIScrollView_ContentInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentInset",
            patch: true
        )
        dict[AppViewAttr_UIScrollView_QMUIInitialInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "qmui_initialContentInset",
            patch: true
        )
        dict[AppViewAttr_UIScrollView_AdjustedInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "AdjustedContentInset",
            setterString: "",
            osVersion: 11
        )
        dict[AppViewAttr_UIScrollView_Behavior_Behavior] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ContentInsetAdjustmentBehavior",
            enumList: "UIScrollViewContentInsetAdjustmentBehavior",
            patch: true,
            osVersion: 11
        )
        dict[AppViewAttr_UIScrollView_IndicatorInset_Inset] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ScrollIndicatorInsets",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_ScrollPaging_ScrollEnabled] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ScrollEnabled",
            getter: .isScrollEnabled,
            patch: false
        )
        dict[AppViewAttr_UIScrollView_ScrollPaging_PagingEnabled] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "PagingEnabled",
            getter: .isPagingEnabled,
            patch: false
        )
        dict[AppViewAttr_UIScrollView_Bounce_Ver] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "AlwaysBounceVertical",
            briefTitle: "Vertical",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_Bounce_Hor] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "AlwaysBounceHorizontal",
            briefTitle: "Horizontal",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_ShowsIndicator_Hor] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ShowsHorizontalScrollIndicator",
            briefTitle: "Horizontal",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_ShowsIndicator_Ver] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ShowsVerticalScrollIndicator",
            briefTitle: "Vertical",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_ContentTouches_Delay] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "DelaysContentTouches",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_ContentTouches_CanCancel] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "CanCancelContentTouches",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_Zoom_MinScale] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "MinimumZoomScale",
            briefTitle: "MinScale",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_Zoom_MaxScale] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "MaximumZoomScale",
            briefTitle: "MaxScale",
            patch: false
        )
        dict[AppViewAttr_UIScrollView_Zoom_Scale] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "ZoomScale",
            briefTitle: "Scale",
            patch: true
        )
        dict[AppViewAttr_UIScrollView_Zoom_Bounce] = AttrInfo(
            className: "UIScrollView",
            fullTitle: "BouncesZoom",
            patch: false
        )
        dict[AppViewAttr_UITableView_Style_Style] = AttrInfo(
            className: "UITableView",
            fullTitle: "Style",
            setterString: "",
            enumList: "UITableViewStyle",
            patch: true
        )
        dict[AppViewAttr_UITableView_SectionsNumber_Number] = AttrInfo(
            className: "UITableView",
            fullTitle: "NumberOfSections",
            setterString: "",
            patch: true
        )
        dict[AppViewAttr_UITableView_RowsNumber_Number] = AttrInfo(
            className: "UITableView",
            getter: .avs_numberOfRows,
            setterString: "",
            typeIfObj: AppViewAttrType.customObj
        )
        dict[AppViewAttr_UITableView_SeparatorInset_Inset] = AttrInfo(
            className: "UITableView",
            fullTitle: "SeparatorInset",
            patch: false
        )
        dict[AppViewAttr_UITableView_SeparatorColor_Color] = AttrInfo(
            className: "UITableView",
            fullTitle: "SeparatorColor",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_UITableView_SeparatorStyle_Style] = AttrInfo(
            className: "UITableView",
            fullTitle: "SeparatorStyle",
            enumList: "UITableViewCellSeparatorStyle",
            patch: true
        )
        dict[AppViewAttr_UITextView_Text_Text] = AttrInfo(
            className: "UITextView",
            fullTitle: "Text",
            typeIfObj: AppViewAttrType.NSString,
            patch: true
        )
        dict[AppViewAttr_UITextView_Font_Name] = AttrInfo(
            className: "UITextView",
            fullTitle: "FontName",
            getter: .avs_fontName,
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_UITextView_Font_Size] = AttrInfo(
            className: "UITextView",
            fullTitle: "FontSize",
            getter: .avs_fontSize,
            setterString: "setAvs_fontSize:",
            patch: true
        )
        dict[AppViewAttr_UITextView_Basic_Editable] = AttrInfo(
            className: "UITextView",
            fullTitle: "Editable",
            getter: .isEditable,
            patch: false
        )
        dict[AppViewAttr_UITextView_Basic_Selectable] = AttrInfo(
            className: "UITextView",
            fullTitle: "Selectable",
            getter: .isSelectable,
            patch: false
        )
        dict[AppViewAttr_UITextView_TextColor_Color] = AttrInfo(
            className: "UITextView",
            fullTitle: "TextColor",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_UITextView_Alignment_Alignment] = AttrInfo(
            className: "UITextView",
            fullTitle: "TextAlignment",
            enumList: "NSTextAlignment",
            patch: true
        )
        dict[AppViewAttr_UITextView_ContainerInset_Inset] = AttrInfo(
            className: "UITextView",
            fullTitle: "TextContainerInset",
            patch: true
        )
        dict[AppViewAttr_UITextField_Font_Name] = AttrInfo(
            className: "UITextField",
            fullTitle: "FontName",
            getter: .avs_fontName,
            setterString: "",
            typeIfObj: AppViewAttrType.NSString,
            patch: false
        )
        dict[AppViewAttr_UITextField_Font_Size] = AttrInfo(
            className: "UITextField",
            fullTitle: "FontSize",
            getter: .avs_fontSize,
            setterString: "setAvs_fontSize:",
            patch: true
        )
        dict[AppViewAttr_UITextField_TextColor_Color] = AttrInfo(
            className: "UITextField",
            fullTitle: "TextColor",
            typeIfObj: AppViewAttrType.UIColor,
            patch: true
        )
        dict[AppViewAttr_UITextField_Alignment_Alignment] = AttrInfo(
            className: "UITextField",
            fullTitle: "TextAlignment",
            enumList: "NSTextAlignment",
            patch: true
        )
        dict[AppViewAttr_UITextField_Text_Text] = AttrInfo(
            className: "UITextField",
            fullTitle: "Text",
            typeIfObj: AppViewAttrType.NSString,
            patch: true
        )
        dict[AppViewAttr_UITextField_Placeholder_Placeholder] = AttrInfo(
            className: "UITextField",
            fullTitle: "Placeholder",
            typeIfObj: AppViewAttrType.NSString,
            patch: true
        )
        dict[AppViewAttr_UITextField_Clears_ClearsOnBeginEditing] = AttrInfo(
            className: "UITextField",
            fullTitle: "ClearsOnBeginEditing",
            patch: false
        )
        dict[AppViewAttr_UITextField_Clears_ClearsOnInsertion] = AttrInfo(
            className: "UITextField",
            fullTitle: "ClearsOnInsertion",
            patch: false
        )
        dict[AppViewAttr_UITextField_CanAdjustFont_CanAdjustFont] = AttrInfo(
            className: "UITextField",
            fullTitle: "AdjustsFontSizeToFitWidth",
            patch: true
        )
        dict[AppViewAttr_UITextField_CanAdjustFont_MinSize] = AttrInfo(
            className: "UITextField",
            fullTitle: "MinimumFontSize",
            patch: true
        )
        dict[AppViewAttr_UITextField_ClearButtonMode_Mode] = AttrInfo(
            className: "UITextField",
            fullTitle: "ClearButtonMode",
            enumList: "UITextFieldViewMode",
            patch: false
        )
        return dict
    }()

    public class func groupIDs() -> [AppViewAttrGroupIdentifier] { allGroupIDs }

    public class func sectionIDs(forGroupID groupID: AppViewAttrGroupIdentifier) -> [AppViewAttrSectionIdentifier] {
        sectionsByGroup[groupID] ?? []
    }

    public class func attrIDs(forSectionID sectionID: AppViewAttrSectionIdentifier) -> [AppViewAttrIdentifier] {
        attrsBySection[sectionID] ?? []
    }

    public class func getHostGroupID(
        _ groupID: AutoreleasingUnsafeMutablePointer<NSString?>?,
        sectionID: AutoreleasingUnsafeMutablePointer<NSString?>?,
        fromAttrID targetAttrID: AppViewAttrIdentifier
    ) {
        var targetGroupID: AppViewAttrGroupIdentifier?
        var targetSecID: AppViewAttrSectionIdentifier?
        outer: for gid in allGroupIDs {
            for secID in sectionIDs(forGroupID: gid) {
                for attrID in attrIDs(forSectionID: secID) where attrID == targetAttrID {
                    targetGroupID = gid
                    targetSecID = secID
                    break outer
                }
            }
        }
        if let groupID, let targetGroupID { groupID.pointee = targetGroupID as NSString }
        if let sectionID, let targetSecID { sectionID.pointee = targetSecID as NSString }
    }

    public class func groupTitle(withGroupID groupID: AppViewAttrGroupIdentifier) -> String {
        let title = groupTitles[groupID]
        assert(title?.isEmpty == false)
        return title ?? ""
    }

    public class func sectionTitle(withSectionID secID: AppViewAttrSectionIdentifier) -> String? {
        sectionTitles[secID]
    }

    private class func info(forAttrID attrID: AppViewAttrIdentifier) -> AttrInfo? { attrInfos[attrID] }

    public class func objectAttrType(withAttrID attrID: AppViewAttrIdentifier) -> AppViewAttrType {
        info(forAttrID: attrID)?.typeIfObj ?? .none
    }

    public class func className(withAttrID attrID: AppViewAttrIdentifier) -> String? {
        let className = info(forAttrID: attrID)?.className
        assert(className?.isEmpty == false)
        return className
    }

    public class func isUIViewProperty(withAttrID attrID: AppViewAttrIdentifier) -> Bool {
        className(withAttrID: attrID) != "CALayer"
    }

    public class func enumListName(withAttrID attrID: AppViewAttrIdentifier) -> String? {
        info(forAttrID: attrID)?.enumList
    }

    public class func needPatchAfterModification(withAttrID attrID: AppViewAttrIdentifier) -> Bool {
        info(forAttrID: attrID)?.patch ?? false
    }

    public class func fullTitle(withAttrID attrID: AppViewAttrIdentifier) -> String? {
        info(forAttrID: attrID)?.fullTitle
    }

    public class func briefTitle(withAttrID attrID: AppViewAttrIdentifier) -> String? {
        let info = info(forAttrID: attrID)
        if let brief = info?.briefTitle { return brief }
        return info?.fullTitle
    }

    public class func getter(withAttrID attrID: AppViewAttrIdentifier) -> Selector? {
        guard let info = info(forAttrID: attrID) else { return nil }
        if let getter = info.getter {
            return getter.selector
        }
        guard let fullTitle = info.fullTitle, !fullTitle.isEmpty else { assertionFailure(); return nil }
        return NSSelectorFromString(fullTitle.prefix(1).lowercased() + fullTitle.dropFirst())
    }

    public class func setter(withAttrID attrID: AppViewAttrIdentifier) -> Selector? {
        guard let info = info(forAttrID: attrID) else { return nil }
        if let setterString = info.setterString {
            if setterString.isEmpty { return nil }
            return NSSelectorFromString(setterString)
        }
        guard let fullTitle = info.fullTitle, !fullTitle.isEmpty else { assertionFailure(); return nil }
        return NSSelectorFromString("set" + fullTitle.prefix(1).uppercased() + fullTitle.dropFirst() + ":")
    }

    public class func hideIfNil(withAttrID attrID: AppViewAttrIdentifier) -> Bool {
        info(forAttrID: attrID)?.hideIfNil ?? false
    }

    public class func minAvailableOSVersion(withAttrID attrID: AppViewAttrIdentifier) -> Int {
        info(forAttrID: attrID)?.osVersion ?? 0
    }
}