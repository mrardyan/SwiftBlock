import Foundation

/// Interface for mapping between DTO and domain entity types.
public protocol __MODULE_NAME__Mapping {
    associatedtype DTO
    associatedtype Entity

    func mapToEntity(_ dto: DTO) -> Entity
    func mapToDTO(_ entity: Entity) -> DTO
}

public extension __MODULE_NAME__Mapping {
    func mapToEntities(_ dtos: [DTO]) -> [Entity] {
        dtos.map { mapToEntity($0) }
    }

    func mapToDTOs(_ entities: [Entity]) -> [DTO] {
        entities.map { mapToDTO($0) }
    }
}

/// Closure-based data mapper implementation.
public struct __MODULE_NAME__Mapper<DTO, Entity>: __MODULE_NAME__Mapping {
    private let toEntityTransform: (DTO) -> Entity
    private let toDTOTransform: (Entity) -> DTO

    public init(
        toEntity: @escaping (DTO) -> Entity,
        toDTO: @escaping (Entity) -> DTO
    ) {
        self.toEntityTransform = toEntity
        self.toDTOTransform = toDTO
    }

    public func mapToEntity(_ dto: DTO) -> Entity {
        toEntityTransform(dto)
    }

    public func mapToDTO(_ entity: Entity) -> DTO {
        toDTOTransform(entity)
    }
}
