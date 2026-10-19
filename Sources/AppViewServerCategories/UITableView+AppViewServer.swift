#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UITableView {
    @objc(avs_numberOfRows)
    public func avs_numberOfRows() -> [NSNumber]? {
        let sectionsCount = UInt(min(numberOfSections, 10))
        let rowsCount = NSArray.appview_arrayWithCount(sectionsCount) { idx in
            NSNumber(value: self.numberOfRows(inSection: Int(idx)))
        }
        return rowsCount.count > 0 ? (rowsCount as? [NSNumber]) : nil
    }
}

#endif
