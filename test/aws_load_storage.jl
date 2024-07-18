using AWS, AWSS3, DotEnv, Test, JSON, GZip, .SaveData
# include("../src/lib/saveFiles.jl")

DotEnv.load!()


aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
aws_region = ENV["AWS_DEFAULT_REGION"]
creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
aws = global_aws_config(; region=aws_region, creds=creds)

file_name = "prova.json"

s3_delete(aws, ENV["AWS_BUCKET_NAME"], file_name)
s3_delete(aws, ENV["AWS_BUCKET_NAME"], file_name * ".gz")

dati_prova = Dict("mesher" => [1, 1, 1], "valid" => true, "solver" => Dict("results" => [[1, 1, 1], [2, 2, 2]], "id" => file_name))

p = S3Path("s3://models-bucket-49718971291/" * file_name)
write(p, JSON.json(dati_prova))



@testset "prova lettura dati in chiaro da s3" begin
    data = JSON.parse(read(p, String))
    @test data isa Dict
    @test haskey(data, "solver")
    @test data["solver"] isa Dict
    @test haskey(data["solver"], "results")
end


upload_json_gz(aws, ENV["AWS_BUCKET_NAME"], file_name, dati_prova)

@testset "prova lettura dati compressi da s3" begin
    @test s3_exists(aws, ENV["AWS_BUCKET_NAME"], file_name)
    dato_aws_compresso = download_json_gz(aws, ENV["AWS_BUCKET_NAME"], file_name)
    @test dato_aws_compresso isa Dict
    @test haskey(dato_aws_compresso, "mesher")
    @test haskey(dato_aws_compresso, "solver")
    @test dato_aws_compresso["solver"] isa Dict
    @test haskey(dato_aws_compresso["solver"], "id")
end