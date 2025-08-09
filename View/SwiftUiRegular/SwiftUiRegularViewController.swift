import UIKit
import SwiftJsonUI

class SwiftUiRegularViewController: BaseViewController {
    
    override var layoutPath: String {
        return "swift_ui_regular"
    }
    
    private lazy var _binding = SwiftUiRegularBinding(viewHolder: self)
    
    override var binding: BaseBinding {
        return _binding
    }
        
    class func newInstance() -> SwiftUiRegularViewController {
        let v = SwiftUiRegularViewController()
        v.title = "title_swift_ui_regular".localized()
        return v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(UIViewCreator.createView(layoutPath, target: self)!)
        binding.bindView()
    }
}
