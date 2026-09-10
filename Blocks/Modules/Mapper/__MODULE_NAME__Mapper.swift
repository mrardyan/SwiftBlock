import Foundation

/// Protocol for data mapper transformers between DTO and Domain Entity types.
public protocol __MODULE_NAME__Mapping {
    associatedtype DTO
    associatedtype Entity

    /// Maps a DTO object into a Domain Entity.
    func mapToEntity(_ dto: DTO) -> Entity

    /// Maps a Domain Entity object into a DTO.
    func mapToDTO(_ entity: Entity) -> DTO
}

public extension __MODULE_NAME__Mapping {
    /// Maps an array of DTO objects into an array of Domain Entities.
    func mapToEntities(_ dtos: [DTO]) -> [Entity] {
        dtos.map { mapToEntity($0) }
    }

    /// Maps an array of Domain Entities into an array of DTO objects.
    func mapToDTOs(_ entities: [Entity]) -> [DTO] {
        entities.map { mapToDTO($0) }
    }
}

/// Closure-based concrete data mapper implementation.
public struct __MODULE_NAME__Mapper<DTO, Entity>: __MODULE_NAME__Mapping {
    private let toEntityTransform: (DTO) -> Entity
    private let toDTOTransform: (Entity) -> DTO

    /// Initializes mapper with conversion closures.
    public init(
        toEntity: @escaping (DTO) -> Entity,
        toDTO: @escaping (Entity) -> DTO
    ) {
        self.toEntityTransform = toEntity
        self.toDTOTransform = toDTO
    }

    /// Transforms DTO to Domain Entity using closure.
    public func mapToEntity(_ dto: DTO) -> Entity {
        toEntityTransform(dto)
    }

    /// Transforms Domain Entity to DTO using closure.
    public func mapToDTO(_ entity: Entity) -> DTO {
        toDTOTransform(entity)
    }
}
