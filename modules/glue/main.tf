variable "resource_prefix" {}
variable "s3_bucket_id_cloudfront_api_logs" {}
variable "s3_bucket_id_cloudfront_web_logs" {}

resource "aws_glue_catalog_database" "accesslogs" {
  name = "${var.resource_prefix}-accesslogs"
}

resource "aws_glue_catalog_table" "cloudfront_api_logs" {
  depends_on    = [aws_glue_catalog_database.accesslogs]
  name          = "cloudfront_api_logs"
  database_name = "${var.resource_prefix}-accesslogs"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "2"
    "compressionType"        = "gzip"
    "classification"         = "csv"
    "columnsOrdered"         = "true"
    "areColumnsQuoted"       = "false"
    "delimiter"              = "\t"
    "commentCharacter"       = "#"
    "typeOfData"             = "file"
  }

  storage_descriptor {
    location      = "s3://${var.s3_bucket_id_cloudfront_api_logs}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "cloudfront_api_logs_ser_de"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = "\t"
      }
    }

    columns {
      name    = "date"
      type    = "date"
    }
    
    columns {
      name    = "time"
      type    = "string"
    }
    
    columns {
      name    = "location"
      type    = "string"
    }
    
    columns {
      name    = "bytes"
      type    = "bigint"
    }
    
    columns {
      name    = "request_ip"
      type    = "string"
    }
    
    columns {
      name    = "method"
      type    = "string"
    }
    
    columns {
      name    = "host"
      type    = "string"
    }
    
    columns {
      name    = "uri"
      type    = "string"
    }
    
    columns {
      name    = "status"
      type    = "int"
    }
    
    columns {
      name    = "referrer"
      type    = "string"
    }
    
    columns {
      name    = "user_agent"
      type    = "string"
    }
    
    columns {
      name    = "query_string"
      type    = "string"
    }
    
    columns {
      name    = "cookie"
      type    = "string"
    }
    
    columns {
      name    = "result_type"
      type    = "string"
    }
    
    columns {
      name    = "request_id"
      type    = "string"
    }
    
    columns {
      name    = "host_header"
      type    = "string"
    }
    
    columns {
      name    = "request_protocol"
      type    = "string"
    }
    
    columns {
      name    = "request_bytes"
      type    = "bigint"
    }
    
    columns {
      name    = "time_taken"
      type    = "float"
    }
    
    columns {
      name    = "xforwarded_for"
      type    = "string"
    }
    
    columns {
      name    = "ssl_protocol"
      type    = "string"
    }
    
    columns {
      name    = "ssl_cipher"
      type    = "string"
    }
    
    columns {
      name    = "response_result_type"
      type    = "string"
    }
    
    columns {
      name    = "http_version"
      type    = "string"
    }
    
    columns {
      name    = "fle_status"
      type    = "string"
    }
    
    columns {
      name    = "fle_encrypted_fields"
      type    = "int"
    }
  }
}

resource "aws_glue_catalog_table" "cloudfront_web_logs" {
  depends_on    = [aws_glue_catalog_database.accesslogs]
  name          = "cloudfront_web_logs"
  database_name = "${var.resource_prefix}-accesslogs"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "2"
    "compressionType"        = "gzip"
    "classification"         = "csv"
    "columnsOrdered"         = "true"
    "areColumnsQuoted"       = "false"
    "delimiter"              = "\t"
    "commentCharacter"       = "#"
    "typeOfData"             = "file"
  }

  storage_descriptor {
    location      = "s3://${var.s3_bucket_id_cloudfront_web_logs}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "cloudfront_web_logs_ser_de"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = "\t"
      }
    }

    columns {
      name    = "date"
      type    = "date"
    }
    
    columns {
      name    = "time"
      type    = "string"
    }
    
    columns {
      name    = "location"
      type    = "string"
    }
    
    columns {
      name    = "bytes"
      type    = "bigint"
    }
    
    columns {
      name    = "request_ip"
      type    = "string"
    }
    
    columns {
      name    = "method"
      type    = "string"
    }
    
    columns {
      name    = "host"
      type    = "string"
    }
    
    columns {
      name    = "uri"
      type    = "string"
    }
    
    columns {
      name    = "status"
      type    = "int"
    }
    
    columns {
      name    = "referrer"
      type    = "string"
    }
    
    columns {
      name    = "user_agent"
      type    = "string"
    }
    
    columns {
      name    = "query_string"
      type    = "string"
    }
    
    columns {
      name    = "cookie"
      type    = "string"
    }
    
    columns {
      name    = "result_type"
      type    = "string"
    }
    
    columns {
      name    = "request_id"
      type    = "string"
    }
    
    columns {
      name    = "host_header"
      type    = "string"
    }
    
    columns {
      name    = "request_protocol"
      type    = "string"
    }
    
    columns {
      name    = "request_bytes"
      type    = "bigint"
    }
    
    columns {
      name    = "time_taken"
      type    = "float"
    }
    
    columns {
      name    = "xforwarded_for"
      type    = "string"
    }
    
    columns {
      name    = "ssl_protocol"
      type    = "string"
    }
    
    columns {
      name    = "ssl_cipher"
      type    = "string"
    }
    
    columns {
      name    = "response_result_type"
      type    = "string"
    }
    
    columns {
      name    = "http_version"
      type    = "string"
    }
    
    columns {
      name    = "fle_status"
      type    = "string"
    }
    
    columns {
      name    = "fle_encrypted_fields"
      type    = "int"
    }
  }
}
