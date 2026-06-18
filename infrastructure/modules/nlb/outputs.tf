output "public_nlb_dns" { value = aws_lb.public.dns_name }
output "internal_nlb_dns" { value = aws_lb.internal.dns_name }
output "nginx_tg_arn" { value = aws_lb_target_group.nginx.arn }
output "app_tg_arn" { value = aws_lb_target_group.app.arn }
