//
//  File.swift
//  
//
//  Created by laijihua on 2023/7/9.
//

import Vapor
import Fluent

struct TagRepositoryImpl: TagRepository {
  var req: Request
  
  init(_ req: Request) {
      self.req = req
  }
  
  func add(inTag: InTag, ownerId: User.IDValue) async throws -> Tag {
    let tag = Tag(name: inTag.name, ownerId: ownerId)
    try await tag.create(on: req.db)
    return tag
  }
  
  func page(ownerId: User.IDValue) async throws -> Page<Tag.Public> {
    return try await Tag.query(on: req.db)
        .group(.and) { group in
          // status 1是正常, 2是删除
          group.filter(\.$owner.$id == ownerId).filter(\.$status == 1)
        }
        .sort(\.$createdAt, .descending)
        .paginate(for:req)
        .map({$0.asPublic()})
  }
  
  func delete(tagIds: InDeleteIds, ownerId: User.IDValue) async throws {
      try await Tag.query(on: req.db)
        .set(\.$status, to: 0)
        .group(.and) {group in
          group.filter(\.$id ~~ tagIds.ids).filter(\.$owner.$id == ownerId)
        }
        .update()
  }
  
  func update(tag: InUpdateTag) async throws {
    try await Tag.query(on: req.db)
      .set(\.$name, to: tag.name)
      .filter(\.$id == tag.id)
      .update()
  }
  
  func allTags(ownerId: User.IDValue) async throws -> [Tag.Public] {
    try await Tag.query(on: req.db)
      .filter(\.$owner.$id == ownerId)
      .sort(\.$createdAt, .descending)
      .all()
      .map({$0.asPublic()})
  }
}
