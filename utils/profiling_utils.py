"""
Profiling utilities for TC-GS using NVTX markers.
NVTX markers help visualize different phases in Nsight Systems timeline.
"""

try:
    from torch.profiler import profile, record_function, ProfilerActivity
    TORCH_PROFILER_AVAILABLE = True
except ImportError:
    TORCH_PROFILER_AVAILABLE = False

try:
    import pynvtx
    PYVTX_AVAILABLE = True
except ImportError:
    PYVTX_AVAILABLE = False

class ProfilingContext:
    """
    Context manager for profiling with NVTX markers.
    Usage:
        with ProfilingContext("render_frame"):
            # your code here
    """
    def __init__(self, name, color="blue"):
        self.name = name
        self.color = color
        self.torch_context = None
        self.nvtx_range = None
        
    def __enter__(self):
        if PYVTX_AVAILABLE:
            # pyNVTX uses color names or hex codes
            color_map = {
                "blue": 0x0000FF,
                "green": 0x00FF00,
                "red": 0xFF0000,
                "yellow": 0xFFFF00,
                "purple": 0xFF00FF,
                "cyan": 0x00FFFF,
            }
            color = color_map.get(self.color, 0x0000FF)
            self.nvtx_range = pynvtx.Range(self.name, color=color)
            self.nvtx_range.__enter__()
        elif TORCH_PROFILER_AVAILABLE:
            self.torch_context = record_function(self.name)
            self.torch_context.__enter__()
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.nvtx_range is not None:
            self.nvtx_range.__exit__(exc_type, exc_val, exc_tb)
        elif self.torch_context is not None:
            self.torch_context.__exit__(exc_type, exc_val, exc_tb)

def mark_phase(name, color="blue"):
    """Decorator to mark a function as a profiling phase."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            with ProfilingContext(name, color):
                return func(*args, **kwargs)
        return wrapper
    return decorator

