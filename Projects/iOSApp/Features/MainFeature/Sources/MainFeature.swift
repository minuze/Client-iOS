import Foundation

import ComposableArchitecture

import PedometerClient_ios
import HealthClient_ios
import LocationClient_ios

public struct MainFeature: ReducerProtocol {
    public init() {}
    
    public struct State: Equatable {
        var todaySteps: Int?
        var currentWeekDay: Int = 0
        var pastSteps: [Int]
        @BindingState
        var currentSpeed: Double = 0
        
        var displayedSteps: Int?
        var nextButtonEnabled: Bool = false
        var prevButtonEnabled: Bool = false
        var achievementRate: Int = 0
        var isLoading: Bool = false
        
        public init(
            todaySteps: Int? = nil,
            currentWeekDay: Int,
            pastSteps: [Int]
        ) {
            self.todaySteps = todaySteps
            self.currentWeekDay = currentWeekDay
            self.pastSteps = pastSteps
        }
    }
    
    public enum Action: BindableAction {
        // View Actions
        case binding(BindingAction<State>)
        case onAppear
        case prevButtonTapped
        case nextButtonTapped
        case settingButtonTapped
        case mySnowmanButtonTapped
        
        // Internal Actions
        case _fetchTodaySteps(Int)
        case _fetchPastSteps([Int])
        case _updateCurrentSpeed(Double)
        case _updateButtonStatus
        case _updateDisplayedStatus
        case _showFetchingStepError
        
        // Coordinator
        case coordinator(CoordinatorAction)
        
        public enum CoordinatorAction {
            case checkTodayPopup
            case pushSettingView
        }
    }
    
    @Dependency(\.pedometerClient)
    var pedometerClient
    
    @Dependency(\.healthClient)
    var healthClient
    
    /// - NOTE(230730) @Duno
    /// @Dependency를 이용하면 asyncStream의 비동기 값이 전달되지 않는 현상
    var locationClient = LocationClient.liveValue
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // state.isLoading = true
                
                state.currentWeekDay = Date().weekdayFromMonday
                
                return .merge (
                    requestHealthClientAuth(),
                    requestLocationClinetAuth(),
                    fetchCurrentSpeed(),
                    fetchPastSteps(),
                    fetchTodaySteps()
                )
                
            case .prevButtonTapped:
                state.currentWeekDay -= 1
                
                return .concatenate(
                    .send(._updateButtonStatus),
                    .send(._updateDisplayedStatus)
                )
                
            case .nextButtonTapped:
                state.currentWeekDay += 1
                
                return .concatenate(
                    .send(._updateButtonStatus),
                    .send(._updateDisplayedStatus)
                )
                
            case .settingButtonTapped:
                return .send(.coordinator(.pushSettingView))
                
            case .mySnowmanButtonTapped:
                return .send(.coordinator(.checkTodayPopup))
                
            case ._fetchTodaySteps(let steps):
                state.todaySteps = steps
                
                return .concatenate(
                    .send(._updateButtonStatus),
                    .send(._updateDisplayedStatus)
                )
                
                // OnApper에서 처음 한 번 실행
            case ._fetchPastSteps(let pastSteps):
                state.pastSteps = pastSteps
                
                return .send(._updateButtonStatus)
                
            case ._updateCurrentSpeed(let speed):
                state.currentSpeed = speed
                
                return .none
                
            case ._updateButtonStatus:
                let existPastSteps = !state.pastSteps.isEmpty
                
                let enableNextButton = state.currentWeekDay < state.pastSteps.count && existPastSteps
                state.nextButtonEnabled = enableNextButton
                
                let enablePrevButton = state.currentWeekDay > 0 && existPastSteps
                state.prevButtonEnabled = enablePrevButton
                
                return .none
                
            case ._updateDisplayedStatus:
                state.displayedSteps = state.currentWeekDay + 1 > state.pastSteps.count
                ? state.todaySteps ?? 0
                : state.pastSteps[state.currentWeekDay]
                
                state.isLoading = false
                
                // TODO: UserDefaults Client에서 가져오기
                let standard = 5000
                state.achievementRate = (state.displayedSteps ?? 0) * 100 / standard
                
                return .none
                
            case ._showFetchingStepError:
                state.todaySteps = nil
                return .none
                
            case .coordinator:
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}

extension MainFeature {
    private func fetchTodaySteps() -> EffectTask<Action> {
        .run { send in
            do {
                for try await steps in pedometerClient.startFetchingSteps() {
                    await send(._fetchTodaySteps(steps))
                }
            } catch {
                await send(._showFetchingStepError)
            }
        }
    }
    
    private func fetchPastSteps() -> EffectTask<Action> {
        .run { send in
            do {
                let pastSteps = try await healthClient.getStepsFromMonday()
                await send(._fetchPastSteps(pastSteps))
            } catch {
                // Error 처리
            }
        }
    }
    
    private func requestHealthClientAuth() -> EffectTask<Action> {
        .run { send in
            do {
                try await healthClient.requestAuthorization()
                let pastSteps = try await healthClient.getStepsFromMonday()
                await send(._fetchPastSteps(pastSteps))
            } catch {
                // Error 처리
            }
        }
    }
    
    private func requestLocationClinetAuth() -> EffectTask<Action> {
        .run { send in
            await locationClient.requestAuthorization()
        }
    }
    
    private func fetchCurrentSpeed() -> EffectTask<Action> {
        return .run { send in
            for await speed in locationClient.getCurrentSpeed() {
                await send(._updateCurrentSpeed(speed))
            }
        }
    }
}

extension MainFeature.State {
    var weekDayString: String {
        switch currentWeekDay {
        case 0: return "월요일"
        case 1: return "화요일"
        case 2: return "수요일"
        case 3: return "목요일"
        case 4: return "금요일"
        case 5: return "토요일"
        case 6: return "일요일"
        default: return "월요일"
        }
    }
}
