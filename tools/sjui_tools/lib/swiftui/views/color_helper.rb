module SjuiTools
  module SwiftUI
    module Views
      module ColorHelper
        def size_to_swiftui(size)
          return nil if size.nil?
          
          case size
          when 'matchParent'
            '.infinity'
          when 'wrapContent'
            nil  # SwiftUIのデフォルト動作
          when Integer, Float
            size.to_s
          when String
            if size.match?(/^\d+$/)
              size
            else
              # その他の文字列はそのまま返す（変数名など）
              size
            end
          else
            size.to_s
          end
        end

        def get_swiftui_color(color_value)
          return "Color.clear" if color_value.nil? || color_value.empty?
          
          # SwiftJsonUIConfiguration.shared.getColor(for:) を使用して色を取得
          # これにより、colorProviderが設定されていればそれを使用し、
          # そうでなければhex変換にフォールバックする
          "SwiftJsonUIConfiguration.shared.getColor(for: \"#{color_value}\") ?? Color.black"
        end
        
        def gradient_direction_to_swiftui(direction)
          # directionプロパティをSwiftUIのグラデーション方向に変換
          case direction
          when 'vertical', 'top_bottom'
            'startPoint: .top, endPoint: .bottom'
          when 'horizontal', 'left_right'
            'startPoint: .leading, endPoint: .trailing'
          when 'bottom_top'
            'startPoint: .bottom, endPoint: .top'
          when 'right_left'
            'startPoint: .trailing, endPoint: .leading'
          when 'topLeft_bottomRight', 'diagonal'
            'startPoint: .topLeading, endPoint: .bottomTrailing'
          when 'topRight_bottomLeft'
            'startPoint: .topTrailing, endPoint: .bottomLeading'
          when 'bottomLeft_topRight'
            'startPoint: .bottomLeading, endPoint: .topTrailing'
          when 'bottomRight_topLeft'
            'startPoint: .bottomTrailing, endPoint: .topLeading'
          else
            'startPoint: .top, endPoint: .bottom'  # デフォルト
          end
        end
      end
    end
  end
end