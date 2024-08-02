

output s3_state_backends {
    description = "A list of s3_backends and their respective state files to lock down access to"
    value = [
        {
            apply_role = aws_iam_role.main_apply_role
            plan_role = aws_iam_role.main_plan_role
            state_file_name = "main-state.json"
        }
    ]
}

output "s3_state_management_role" {
  description = "If one of the s3 state backend roles is also self-managing the bucket after initial creation, then we add add that role here"
  value = aws_iam_role.main_apply_role
}

output "triage_user_role" {
  description = "User role that is allowed to access the s3 backend bucket as an admin user - full permissions"
  value = aws_iam_role.triage_user_role
}
