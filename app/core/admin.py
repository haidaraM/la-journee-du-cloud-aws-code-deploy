from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _

from .models import AppUser


# Register your models here.
@admin.register(AppUser)
class AppUser(UserAdmin):
    list_per_page = 50

    list_display = (
        "email",
        "first_name",
        "last_name",
        "is_active",
        "last_login",
        "created_at",
    )
    search_fields = [
        "fullname",
        "email",
        "is_email_verified",
        "last_login",
    ]

    readonly_fields = ["last_login", "date_joined", "created_at", "updated_at"]

    ordering = ["-created_at"]

    fieldsets = (
        (
            _("Personal info"),
            {"fields": (("first_name", "last_name", "email"),)},
        ),
        (
            _("Important dates"),
            {"fields": ("last_login", "date_joined", "created_at", "updated_at")},
        ),
        (
            _("Permissions"),
            {
                "fields": (
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                ),
            },
        ),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (("first_name", "last_name", "email"),),
            },
        ),
        (_("Password"), {"fields": ("password1", "password2")}),
    )
