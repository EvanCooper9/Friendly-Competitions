import Combine
import ECKit
import Factory
import Popovers
import SwiftUI

extension View {
    func withTutorialPopup(for step: TutorialStep, position: PopoverPosition = .top) -> some View {
        modifier(PopoverOnAppear(step: step, position: position))
    }
}

enum PopoverPosition {
    case top
    case bottom
    case left
    case right
    
    fileprivate var originAnchor: Popover.Attributes.Position.Anchor {
        switch self {
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .left:
            return .left
        case .right:
            return .right
        }
    }
    
    fileprivate var popoverAnchor: Popover.Attributes.Position.Anchor {
        switch self {
        case .top:
            return .bottom
        case .bottom:
            return .top
        case .left:
            return .right
        case .right:
            return .left
        }
    }
}
        
extension Binding where Value == Optional<TutorialStep> {
    func `is`(_ step: TutorialStep) -> Binding<Bool> {
        .init {
            wrappedValue == step
        } set: { presented in
            guard !presented else { return }
            wrappedValue = nil
        }
    }
}

private struct PopoverOnAppear: ViewModifier {
    
    @StateObject private var viewModel: PopoverOnAppearViewModel
    
    init(step: TutorialStep, position: PopoverPosition) {
        _viewModel = .init(wrappedValue: .init(step: step, position: position))
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .frameTag(viewModel.tag)
            .popover(
                present: $viewModel.present,
                attributes: {
                    $0.position = .absolute(
                        originAnchor: viewModel.position.originAnchor,
                        popoverAnchor: viewModel.position.popoverAnchor
                    )
                    $0.sourceFrameInset = .init(all: -20)
                }
            ) {
                Templates.BackgroundWithArrowAttachedToSource(position: viewModel.position, sourceTag: viewModel.tag) {
                    Text(viewModel.description)
                        .padding()
                }
            }
    }
}

extension Templates {
    struct BackgroundWithArrowAttachedToSource<Content: View>: View {
        
        let position: PopoverPosition
        let sourceTag: AnyHashable
        let content: () -> Content
        
        var body: some View {
            content().background {
                PopoverReader { context in
                    CustomBackgroundWithArrow(
                        arrowPosition: {
                            let popoverWindow = context.frame
                            let anchor = context.window.frameTagged(sourceTag)
                            
                            let popoverXRange = popoverWindow.minX...popoverWindow.maxX
                            let popoverYRange = popoverWindow.minY...popoverWindow.maxY
                            let anchorXRange = anchor.minX...anchor.maxX
                            let anchroYRange = anchor.minY...anchor.maxY
                            
                            let midX = popoverXRange.intersect(anchorXRange)?.middle ?? 0
                            let midY = popoverYRange.intersect(anchroYRange)?.middle ?? 0
                            
                            switch position {
                            case .top:
                                return .bottom(xOffset: midX - popoverXRange.lowerBound)
                            case .bottom:
                                return .top(xOffset: midX - popoverXRange.lowerBound)
                            case .left:
                                return .right(yOffset: midY - popoverYRange.lowerBound)
                            case .right:
                                return .left(yOffset: midY - popoverYRange.lowerBound)
                            }
                        }()
                    )
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.5), radius: 10)
                }
            }
        }
    }
}

private final class PopoverOnAppearViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    let description: String
    let position: PopoverPosition
    let tag: String
    @Published var present = false
    
    // MARK: - Private Properties
    
    private let visible = CurrentValueSubject<Bool, Never>(false)
    
    @Injected(Container.tutorialManager) private var tutorialManager
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init(step: TutorialStep, position: PopoverPosition) {
        description = step.description
        self.position = position
        tag = step.description
        
        Publishers
            .CombineLatest(
                visible,
                tutorialManager.remainingSteps.map(\.first)
            )
            .map { visible, currentStep in
                guard visible else { return false }
                return step == currentStep
            }
            .assign(to: &$present)
        
        $present
            .removeDuplicates()
            .dropFirst()
            .sink(withUnretained: self) { strongSelf, present in
                guard !present else { return }
                strongSelf.tutorialManager.complete(step: step)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func onAppear() {
        visible.send(true)
    }
    
    func onDisappear() {
        visible.send(false)
    }
}

struct CustomBackgroundWithArrow: Shape {
    
    enum ArrowPosition {
        case top(xOffset: CGFloat)
        case bottom(xOffset: CGFloat)
        case left(yOffset: CGFloat)
        case right(yOffset: CGFloat)
        
        var rotation: CGFloat {
            switch self {
            case .top:
                return 0
            case .bottom:
                return .pi
            case .left:
                return -.pi / 2
            case .right:
                return .pi / 2
            }
        }
        
        var offset: CGFloat {
            switch self {
            case let .top(xOffset):
                return xOffset
            case let .bottom(xOffset):
                return xOffset
            case let .left(yOffset):
                return yOffset
            case let .right(yOffset):
                return yOffset
            }
        }
    }
    
    private enum Constants {
        static let arrowWidth = 50.0
        static let arrowHeight = 20.0
        static let arrowEdgeCornerRadius = 20.0
        static let arrowTipCornerRadius = 4.0
    }

    let arrowPosition: ArrowPosition
    
    /// Path for the triangular arrow.
    private var arrow: Path {
        let arrowHalfWidth = (Constants.arrowWidth / 2) * 0.8

        let arrowPath = Path { path in
            let arrowRect = CGRect(x: 0, y: 0, width: Constants.arrowWidth, height: Constants.arrowHeight)

            path.move(to: CGPoint(x: arrowRect.minX, y: arrowRect.maxY))
            path.addArc(
                tangent1End: CGPoint(x: arrowRect.midX - arrowHalfWidth, y: arrowRect.maxY),
                tangent2End: CGPoint(x: arrowRect.midX, y: arrowRect.minX),
                radius: Constants.arrowEdgeCornerRadius
            )
            path.addArc(
                tangent1End: CGPoint(x: arrowRect.midX, y: arrowRect.minX),
                tangent2End: CGPoint(x: arrowRect.midX + arrowHalfWidth, y: arrowRect.maxY),
                radius: Constants.arrowTipCornerRadius
            )
            path.addArc(
                tangent1End: CGPoint(x: arrowRect.midX + arrowHalfWidth, y: arrowRect.maxY),
                tangent2End: CGPoint(x: arrowRect.maxX, y: arrowRect.maxY),
                radius: Constants.arrowEdgeCornerRadius
            )
            path.addLine(to: CGPoint(x: arrowRect.maxX, y: arrowRect.maxY))
        }
        
        return arrowPath
            .applying(.init(rotationAngle: arrowPosition.rotation))
    }
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addRoundedRect(
                in: rect,//.inset(by: edgeInset),
                cornerSize: .init(width: 10, height: 10)
            )
            
            let arrow = arrow.applying(.init(
                translationX: xOffset(with: rect),
                y: yOffset(with: rect)
            ))
            path.addPath(arrow)
        }
    }
    
    private func xOffset(with rect: CGRect) -> CGFloat {
        switch arrowPosition {
        case let .top(xOffset):
            return xOffset - Constants.arrowWidth / 2
        case let .bottom(xOffset):
            return xOffset + Constants.arrowWidth / 2
        case .left:
            return -Constants.arrowHeight
        case .right:
            return rect.width + Constants.arrowHeight
        }
    }
    
    private func yOffset(with rect: CGRect) -> CGFloat {
        switch arrowPosition {
        case .top:
            return -Constants.arrowHeight
        case .bottom:
            return rect.height + Constants.arrowHeight
        case let .left(yOffset):
            return yOffset + Constants.arrowWidth / 2
        case let .right(yOffset):
            return yOffset - Constants.arrowWidth / 2
        }
    }
}

struct WithTutorialPopover_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 50) {
                HStack(spacing: 50) {
                    CustomBackgroundWithArrow(arrowPosition: .left(yOffset: 100))
                        .stroke(Color.gray)
                    CustomBackgroundWithArrow(arrowPosition: .right(yOffset: 100))
                        .stroke(Color.gray)
                }
                
                CustomBackgroundWithArrow(arrowPosition: .top(xOffset: 100))
                        .stroke(Color.gray)
                CustomBackgroundWithArrow(arrowPosition: .bottom(xOffset: 100))
                        .stroke(Color.gray)
            }
            .padding(50)
            
            Rectangle()
                .height(1)
                .offset(y: 150)
            
            Rectangle()
                .width(1)
                .offset(x: 150)
        }
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        guard !range.contains(self) else { return self }
        return range.lowerBound > self ? range.lowerBound : range.upperBound
    }
}

extension ClosedRange where Bound == CGFloat {
    var middle: Bound { (lowerBound + upperBound) / 2 }
}

extension ClosedRange {
    func intersect(_ other: ClosedRange<Bound>) -> ClosedRange<Bound>? {
        let lowerBoundMax = Swift.max(self.lowerBound, other.lowerBound)
        let upperBoundMin = Swift.min(self.upperBound, other.upperBound)

        let lowerBeforeUpper = lowerBoundMax <= self.upperBound && lowerBoundMax <= other.upperBound
        let upperBeforeLower = upperBoundMin >= self.lowerBound && upperBoundMin >= other.lowerBound

        if lowerBeforeUpper && upperBeforeLower {
            return lowerBoundMax...upperBoundMin
        }

        return nil
    }
}
