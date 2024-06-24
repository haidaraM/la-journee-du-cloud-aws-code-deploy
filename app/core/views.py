# Create your views here.
import os
import random

from django.http import JsonResponse


def index(request):
    """
    Index view displaying a message and version
    :param request:
    :return:
    """
    version = os.getenv("VERSION", "not-set")

    error_percent = int(os.getenv("ERROR_PERCENTAGE", 0))

    if random.uniform(0, 100) < error_percent:
        raise ValueError(
            "Internal error: An error occurred while processing your request"
        )

    return JsonResponse({"message": "Demo La Journée du Cloud 2024", "version": version})

