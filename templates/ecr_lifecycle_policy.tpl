{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than ${untagged_expire_days} days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": ${untagged_expire_days}
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last ${keep_latest_count} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${keep_latest_count}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
