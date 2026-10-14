#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 03: Testing ALL 9 Feature Block subcommands ('swiftblock add')..."

    cd "$TEST_DIR/TestNewApp"

    "$SWIFTBLOCK_BIN" snap scene Profile
    "$SWIFTBLOCK_BIN" snap usecase FetchProfile
    "$SWIFTBLOCK_BIN" snap repository ProfileRepo
    "$SWIFTBLOCK_BIN" snap service ProfileService
    "$SWIFTBLOCK_BIN" snap entity ProfileDTO
    "$SWIFTBLOCK_BIN" snap coordinator ProfileFlow
    "$SWIFTBLOCK_BIN" snap component AvatarView
    "$SWIFTBLOCK_BIN" snap mapper ProfileMapper
    "$SWIFTBLOCK_BIN" snap validator EmailValidator

    assert_file_exists "App/Sources/Features/profile/scene/ProfileView.swift" "Scene block ProfileView.swift present"
    assert_file_exists "App/Sources/Features/fetchprofile/usecase/FetchProfileUseCase.swift" "UseCase block FetchProfileUseCase.swift present"
    assert_file_exists "App/Sources/Features/profilerepo/repository/ProfileRepoRepository.swift" "Repository block ProfileRepoRepository.swift present"
    assert_file_exists "App/Sources/Features/profileservice/service/ProfileServiceService.swift" "Service block ProfileServiceService.swift present"
    assert_file_exists "App/Sources/Features/profiledto/entity/ProfileDTOEntity.swift" "Entity block ProfileDTOEntity.swift present"
    assert_file_exists "App/Sources/Features/profileflow/coordinator/ProfileFlowCoordinator.swift" "Coordinator block ProfileFlowCoordinator.swift present"
    assert_file_exists "App/Sources/Features/avatarview/component/AvatarViewComponent.swift" "Component block AvatarViewComponent.swift present"
    assert_file_exists "App/Sources/Features/profilemapper/mapper/ProfileMapperMapper.swift" "Mapper block ProfileMapperMapper.swift present"
    assert_file_exists "App/Sources/Features/emailvalidator/validator/EmailValidatorValidator.swift" "Validator block EmailValidatorValidator.swift present"

    cd "$TEST_DIR"
}

run_scenario
