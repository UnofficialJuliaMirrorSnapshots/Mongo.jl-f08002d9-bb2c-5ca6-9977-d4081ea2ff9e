
using LibBSON, Mongo, Base.Test

@testset "Mongo" begin
    client = MongoClient()
    collection = MongoCollection(client, "foo", "bar")
    oid = BSONOID()

    @testset "variables" begin
      @test collection.client == client
      @test collection.db == "foo"
      @test collection.name == "bar"
    end

    @testset "insert" begin
        insert(collection, ("_id" => oid, "hello" => "before"))
        @test count(collection, ("_id" => oid)) == 1
        @test count(collection) == 1
        for item in find(collection, ("_id" => oid), ("_id" => false, "hello" => true))
            @test dict(item) == Dict("hello" => "before")
        end
    end

    @testset "update" begin
        update(
            collection,
            ("_id" => oid),
            set("hello" => "after")
            )

        @test count(collection, ("_id" => oid)) == 1
        for item in find(collection, ("_id" => oid), ("_id" => false, "hello" => true))
            @test dict(item) == Dict("hello" => "after")
        end
    end

    @testset "command_simple" begin
        reply = command_simple(
            client,
            "foo",
            Dict(
               "count" => "bar",
               "query" => Dict("_id" => oid))
            )
        @test reply["n"] == 1
    end

    @testset "delete" begin
        delete(
            collection,
            ("_id" => oid)
            )
        @test count(collection, ("_id" => oid)) == 0
        @test count(collection) == 0
    end
end

@testset "Mongo: bad host/port" begin
    client = MongoClient("bad-host-name", 9999)
    collection = MongoCollection(client, "foo", "bar")
    @test_throws ErrorException insert(collection, ("foo" => "bar"))
end

@testset "Query building helpers" begin
    client = MongoClient()
    ppl = MongoCollection(client, "foo", "ppl")
    person(name, age) = insert(ppl, ("name" => name, "age" => age))
    person("Tim", 25)
    person("Jason", 21)
    person("Jim", 87)

    @testset "orderby" begin
        @test first(find(ppl, (query(), orderby("age" => -1))))["name"] == "Jim"
        @test first(find(ppl, (query(), orderby("age" => 1))))["name"] == "Jason"
    end

    @testset "gt and lt" begin
        @test first(find(ppl, query("age" => lt(25))))["name"] == "Jason"
        @test first(find(ppl, query("age" => gt(50))))["name"] == "Jim"
    end

    @testset "in and nin" begin
        @test first(find(ppl, query("age" => in([21]))))["name"] == "Jason"
        @test first(find(ppl, query("age" => nin([21,25]))))["name"] == "Jim"
    end

    @testset "eq and ne" begin
        @test first(find(ppl, query("age" => eq(21))))["name"] == "Jason"
        @test first(find(ppl, query("age" => ne(87))))["name"] != "Jim"
    end

    @testset "update with operator" begin
        update(ppl, ("age" => 87), set("age" => 88))
        @test first(find(ppl, query("name" => "Jim")))["age"] == 88
    end

    delete(ppl, ())
end
