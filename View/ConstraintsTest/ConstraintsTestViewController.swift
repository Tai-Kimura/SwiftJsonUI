import UIKit
import SwiftJsonUI

class ConstraintsTestViewController: BaseViewController {
    
    override var layoutPath: String {
        return "constraints_test"
    }
    
    private lazy var _binding = ConstraintsTestBinding(viewHolder: self)
    
    override var binding: BaseBinding {
        return _binding
    }
        
    class func newInstance() -> ConstraintsTestViewController {
        let v = ConstraintsTestViewController()
        v.title = "title_constraints_test".localized()
        return v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(UIViewCreator.createView(layoutPath, target: self)!)
        binding.bindView()
    }
}
