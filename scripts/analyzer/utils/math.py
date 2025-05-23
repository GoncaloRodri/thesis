import math


def get_mean(data: list) -> float:
    """
    Calculate the mean of a list of numbers.

    Args:
        data (list): List of numbers.

    Returns:
        float: Mean of the numbers.
    """
    return sum(data) / len(data) if data else 0.0

def get_variance(data: list) -> float:
    """
    Calculate the variance of a list of numbers.

    Args:
        data (list): List of numbers.

    Returns:
        float: Variance of the numbers.
    """
    mean = get_mean(data)
    return sum((x - mean) ** 2 for x in data) / len(data) if data else 0.0

def get_std_deviation(data: list) -> float:
    """
    Calculate the standard deviation of a list of numbers.

    Args:
        data (list): List of numbers.

    Returns:
        float: Standard deviation of the numbers.
    """
    return math.sqrt(get_variance(data)) if data else 0.0

def get_min(data: list) -> float:
    """
    Get the minimum value from a list of numbers.

    Args:
        data (list): List of numbers.

    Returns:
        float: Minimum value.
    """
    return min(data, default=0.0)
def get_max(data: list) -> float:
    """
    Get the maximum value from a list of numbers.
    Args:
        data (list): List of numbers.
    Returns:
        float: Maximum value.
    """
    return max(data, default=0.0)

def get_sum(data: list) -> float:
    """
    Get the sum of a list of numbers.

    Args:
        data (list): List of numbers.

    Returns:
        float: Sum of the numbers.
    """
    return sum(data) if data else 0.0