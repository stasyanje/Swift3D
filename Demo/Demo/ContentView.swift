import SwiftUI
import Swift3D

struct ContentView: View {
  enum Content: CaseIterable {
    case introAnimation
    case cow
    case pbr
    case shapes
    case seats
  }
  
  let pages = Content.allCases
  @State var curPage: Int = 0

  // MARK: - View

  var body: some View {
    VStack {
      PageView(
        pages: pages.map { page in
          VStack {
            switch page {
            case .cow:
              CowSample()
            case .introAnimation:
              IntroAnimationSample()
            case .seats:
              SeatsSample()
            case .pbr:
              PBRSample()
            case .shapes:
              ShapesSample()
            }
            Text(page == Content.allCases.last ? "✨Done!✨" : "Swipe for more ➡️").font(.callout).padding(.top)
          }
        },
        currentPage: $curPage
      )
    }
  }
}

private struct Preview: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
