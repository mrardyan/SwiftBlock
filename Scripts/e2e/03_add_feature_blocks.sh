#!/usr/bin/env bash

run_scenario() {
    log_step "Scenario 03: Testing ALL 9 Feature Block subcommands ('swiftblock add')..."

    cd "$TEST_DIR/TestNewApp"

    "$SWIFTBLOCK_BIN" add scene Profile -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add usecase FetchProfile -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add repository ProfileRepo -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add service ProfileService -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add entity ProfileDTO -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add coordinator ProfileFlow -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add component AvatarView -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add mapper ProfileMapper -t "$MODULES_PATH"
    "$SWIFTBLOCK_BIN" add validator EmailValidator -t "$MODULES_PATH"

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
