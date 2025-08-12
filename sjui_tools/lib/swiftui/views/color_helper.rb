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

        def hex_to_swiftui_color(hex)
          return "Color.clear" if hex.nil? || hex.empty?
          
          # 16進数カラーコードの処理
          if hex.start_with?('#')
            hex = hex[1..-1]
          end
          
          hex = hex.upcase
          
          if hex.length == 6
            # 6桁の16進数（RGB）
            r = hex[0..1].to_i(16) / 255.0
            g = hex[2..3].to_i(16) / 255.0
            b = hex[4..5].to_i(16) / 255.0
            "Color(red: #{r}, green: #{g}, blue: #{b})"
          elsif hex.length == 8
            # 8桁の16進数（ARGB または RGBA）
            # SwiftJsonUIは通常ARGBフォーマットを使用
            a = hex[0..1].to_i(16) / 255.0
            r = hex[2..3].to_i(16) / 255.0
            g = hex[4..5].to_i(16) / 255.0
            b = hex[6..7].to_i(16) / 255.0
            "Color(red: #{r}, green: #{g}, blue: #{b}, opacity: #{a})"
          else
            "Color.black"  # デフォルト
          end
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