import SwiftUI
import UIKit

// Pulled from Apple's Interfacing with UIKit example : https://developer.apple.com/tutorials/swiftui/interfacing-with-uikit
struct PageView<Page: View>: UIViewControllerRepresentable {
  var pages: [Page]
  @Binding var currentPage: Int

  func makeCoordinator() -> PageViewCoordinator {
    PageViewCoordinator(
      children: pages.map {
        let vc = UIHostingController(rootView: $0)
        vc.view.backgroundColor = UIColor.clear
        return vc
      },
      didTransition: { index in
        currentPage = index
      }
    )
  }

  func makeUIViewController(context: Context) -> UIPageViewController {
    let pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal
    )
    pageViewController.dataSource = context.coordinator
    pageViewController.delegate = context.coordinator
    pageViewController.view.backgroundColor = UIColor.clear

    return pageViewController
  }

  func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
    pageViewController.setViewControllers(
      [context.coordinator.controllers[currentPage]],
      direction: .forward,
      animated: true
    )
  }
}

final class PageViewCoordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  let controllers: [UIViewController]
  let didTransition: (Int) -> Void

  init(children: [UIViewController], didTransition: @escaping (Int) -> Void) {
    self.controllers = children
    self.didTransition = didTransition
  }
  
  // MARK: - UIPageViewControllerDataSource

  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard let index = controllers.firstIndex(of: viewController), index > 0 else {
      return nil
    }

    return controllers[index - 1]
  }

  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    guard let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 else {
      return nil
    }

    return controllers[index + 1]
  }
  
  // MARK: - UIPageViewControllerDelegate

  func pageViewController(
    _ pageViewController: UIPageViewController,
    didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController],
    transitionCompleted completed: Bool
  ) {
    if completed,
      let visibleViewController = pageViewController.viewControllers?.first,
      let index = controllers.firstIndex(of: visibleViewController)
    {
      didTransition(index)
    }
  }
}
