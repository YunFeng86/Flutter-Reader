// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRuleCollection on Isar {
  IsarCollection<Rule> get rules => this.collection();
}

const RuleSchema = CollectionSchema(
  name: r'Rule',
  id: -2659006343538057288,
  properties: {
    r'autoMarkRead': PropertySchema(
      id: 0,
      name: r'autoMarkRead',
      type: IsarType.bool,
    ),
    r'autoStar': PropertySchema(
      id: 1,
      name: r'autoStar',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'enabled': PropertySchema(
      id: 3,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'keyword': PropertySchema(
      id: 4,
      name: r'keyword',
      type: IsarType.string,
    ),
    r'matchAuthor': PropertySchema(
      id: 5,
      name: r'matchAuthor',
      type: IsarType.bool,
    ),
    r'matchContent': PropertySchema(
      id: 6,
      name: r'matchContent',
      type: IsarType.bool,
    ),
    r'matchLink': PropertySchema(
      id: 7,
      name: r'matchLink',
      type: IsarType.bool,
    ),
    r'matchTitle': PropertySchema(
      id: 8,
      name: r'matchTitle',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'notify': PropertySchema(
      id: 10,
      name: r'notify',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _ruleEstimateSize,
  serialize: _ruleSerialize,
  deserialize: _ruleDeserialize,
  deserializeProp: _ruleDeserializeProp,
  idName: r'id',
  indexes: {
    r'enabled': IndexSchema(
      id: -4605800638041043998,
      name: r'enabled',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'enabled',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'keyword': IndexSchema(
      id: 5840366397742622134,
      name: r'keyword',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'keyword',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _ruleGetId,
  getLinks: _ruleGetLinks,
  attach: _ruleAttach,
  version: '3.1.0+1',
);

int _ruleEstimateSize(
  Rule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.keyword.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _ruleSerialize(
  Rule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoMarkRead);
  writer.writeBool(offsets[1], object.autoStar);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.enabled);
  writer.writeString(offsets[4], object.keyword);
  writer.writeBool(offsets[5], object.matchAuthor);
  writer.writeBool(offsets[6], object.matchContent);
  writer.writeBool(offsets[7], object.matchLink);
  writer.writeBool(offsets[8], object.matchTitle);
  writer.writeString(offsets[9], object.name);
  writer.writeBool(offsets[10], object.notify);
  writer.writeDateTime(offsets[11], object.updatedAt);
}

Rule _ruleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Rule();
  object.autoMarkRead = reader.readBool(offsets[0]);
  object.autoStar = reader.readBool(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.enabled = reader.readBool(offsets[3]);
  object.id = id;
  object.keyword = reader.readString(offsets[4]);
  object.matchAuthor = reader.readBool(offsets[5]);
  object.matchContent = reader.readBool(offsets[6]);
  object.matchLink = reader.readBool(offsets[7]);
  object.matchTitle = reader.readBool(offsets[8]);
  object.name = reader.readString(offsets[9]);
  object.notify = reader.readBool(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  return object;
}

P _ruleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ruleGetId(Rule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ruleGetLinks(Rule object) {
  return [];
}

void _ruleAttach(IsarCollection<dynamic> col, Id id, Rule object) {
  object.id = id;
}

extension RuleQueryWhereSort on QueryBuilder<Rule, Rule, QWhere> {
  QueryBuilder<Rule, Rule, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhere> anyEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'enabled'),
      );
    });
  }
}

extension RuleQueryWhere on QueryBuilder<Rule, Rule, QWhereClause> {
  QueryBuilder<Rule, Rule, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> enabledEqualTo(bool enabled) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'enabled',
        value: [enabled],
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> enabledNotEqualTo(bool enabled) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'enabled',
              lower: [],
              upper: [enabled],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'enabled',
              lower: [enabled],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'enabled',
              lower: [enabled],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'enabled',
              lower: [],
              upper: [enabled],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> keywordEqualTo(String keyword) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'keyword',
        value: [keyword],
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> keywordNotEqualTo(
      String keyword) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [],
              upper: [keyword],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [keyword],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [keyword],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [],
              upper: [keyword],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RuleQueryFilter on QueryBuilder<Rule, Rule, QFilterCondition> {
  QueryBuilder<Rule, Rule, QAfterFilterCondition> autoMarkReadEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoMarkRead',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> autoStarEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoStar',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keyword',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keyword',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyword',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> keywordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keyword',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchAuthorEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchAuthor',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchContentEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchContent',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchLinkEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchLink',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchTitleEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchTitle',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> notifyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notify',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RuleQueryObject on QueryBuilder<Rule, Rule, QFilterCondition> {}

extension RuleQueryLinks on QueryBuilder<Rule, Rule, QFilterCondition> {}

extension RuleQuerySortBy on QueryBuilder<Rule, Rule, QSortBy> {
  QueryBuilder<Rule, Rule, QAfterSortBy> sortByAutoMarkRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoMarkRead', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByAutoMarkReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoMarkRead', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByAutoStar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoStar', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByAutoStarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoStar', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByKeyword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByKeywordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchAuthor', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchAuthor', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchContent', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchContent', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchLink', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchLinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchLink', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTitle', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTitle', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByNotify() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notify', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByNotifyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notify', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension RuleQuerySortThenBy on QueryBuilder<Rule, Rule, QSortThenBy> {
  QueryBuilder<Rule, Rule, QAfterSortBy> thenByAutoMarkRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoMarkRead', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByAutoMarkReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoMarkRead', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByAutoStar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoStar', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByAutoStarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoStar', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByKeyword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByKeywordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchAuthor', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchAuthor', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchContent', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchContent', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchLink', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchLinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchLink', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTitle', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTitle', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByNotify() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notify', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByNotifyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notify', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension RuleQueryWhereDistinct on QueryBuilder<Rule, Rule, QDistinct> {
  QueryBuilder<Rule, Rule, QDistinct> distinctByAutoMarkRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoMarkRead');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByAutoStar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoStar');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByKeyword(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyword', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByMatchAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchAuthor');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByMatchContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchContent');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByMatchLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchLink');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByMatchTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchTitle');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByNotify() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notify');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension RuleQueryProperty on QueryBuilder<Rule, Rule, QQueryProperty> {
  QueryBuilder<Rule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> autoMarkReadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoMarkRead');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> autoStarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoStar');
    });
  }

  QueryBuilder<Rule, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<Rule, String, QQueryOperations> keywordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyword');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> matchAuthorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchAuthor');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> matchContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchContent');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> matchLinkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchLink');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> matchTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchTitle');
    });
  }

  QueryBuilder<Rule, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Rule, bool, QQueryOperations> notifyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notify');
    });
  }

  QueryBuilder<Rule, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
