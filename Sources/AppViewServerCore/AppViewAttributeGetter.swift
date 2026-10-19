import Foundation

/// Typed attribute getter keys (replaces scattered `getterString` literals in blueprint).
public enum AppViewAttributeGetter: String, CaseIterable {
    case avs_relatedClassChainList
    case avs_accessibilityTraitsDescription
    case avs_selfRelation
    case avs_horizontalContentHuggingPriority
    case avs_verticalContentHuggingPriority
    case avs_horizontalContentCompressionResistancePriority
    case avs_verticalContentCompressionResistancePriority
    case avs_constraints
    case avs_layoutIssues
    case avs_installedConstraints
    case isHidden
    case opacity
    case isUserInteractionEnabled
    case masksToBounds
    case avs_backgroundColor
    case avs_borderColor
    case avs_shadowColor
    case avs_shadowOffsetWidth
    case avs_shadowOffsetHeight
    case avs_blurEffectStyleNumber
    case avs_imageSourceName
    case avs_imageViewOidIfHasImage
    case avs_fontSize
    case avs_fontName
    case isEnabled
    case isSelected
    case isScrollEnabled
    case isPagingEnabled
    case avs_numberOfRows
    case isEditable
    case isSelectable
    case isAccessibilityElement

    public var selector: Selector {
        NSSelectorFromString(rawValue)
    }
}
