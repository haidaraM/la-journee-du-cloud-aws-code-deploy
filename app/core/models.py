from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _


class BaseMetaModel(models.Model):
    """
    Base metamodel for all objects
    """

    created_at = models.DateTimeField(auto_now_add=True, help_text="Date de création")
    updated_at = models.DateTimeField(auto_now=True, help_text="Date de mise à jour")

    @staticmethod
    def get_readonly_fields():
        return ["created_at", "updated_at"]

    class Meta:
        abstract = True


class AppUserManager(BaseUserManager):
    def create_user(self, email, first_name, last_name, password=None) -> "AppUser":
        """
        Creates and saves a User with the given email, first name and last name.
        """
        if not email:
            raise ValueError("Users must have an email address")

        user = self.model(
            email=self.normalize_email(email),
            first_name=first_name,
            last_name=last_name,
        )

        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(
            self, email, first_name, last_name, password=None
    ) -> "AppUser":
        """
        Creates and saves a superuser with the given email, date of
        birth and password.
        """
        user = self.create_user(
            email, password=password, first_name=first_name, last_name=last_name
        )
        user.is_staff = True
        user.is_active = True
        user.is_superuser = True
        user.save(using=self._db)
        return user


# Create your models here.
class AppUser(AbstractUser, BaseMetaModel):
    objects = AppUserManager()

    email = models.EmailField(_("email address"), unique=True)

    username = None  # We don't need this anymore
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    def __str__(self):
        return f"{self.get_full_name()}"

    class Meta:
        verbose_name = "User"
        verbose_name_plural = "Users"
