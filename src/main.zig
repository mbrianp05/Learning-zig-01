const std = @import("std");

const Node = struct {
    value: i32,
    left: ?*Node = null,
    right: ?*Node = null,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, value: i32) !*Node {
        const node = try allocator.create(Node);
        node.* = .{ .value = value, .allocator = allocator };

        return node;
    }

    pub fn deinit(self: *Node, allocator: std.mem.Allocator) void {
        if (self.left) |left| {
            left.deinit(allocator);
        }

        if (self.right) |right| {
            right.deinit(allocator);
        }

        allocator.destroy(self);
    }

    pub fn search(self: *Node, value: i32) ?*Node {
        if (self.value == value) return self;

        if (self.value > value) {
            if (self.left) |left| {
                return left.search(value);
            }

            return null;
        }

        if (self.right) |right| {
            return right.search(value);
        }

        return null;
    }

    pub fn insert(self: *Node, value: i32) !void {
        if (self.value == value) {
            return;
        }

        if (self.value > value) {
            if (self.left) |left| {
                try left.insert(value);
                return;
            }

            self.left = try Node.init(self.allocator, value);
            return;
        }

        if (self.right) |right| {
            try right.insert(value);
            return;
        }

        self.right = try Node.init(self.allocator, value);
    }

    pub fn inorder(self: *Node) void {
        if (self.left) |left| {
            left.inorder();
        }

        std.debug.print("{d}\n", .{self.value});

        if (self.right) |right| {
            right.inorder();
        }
    }
};

pub fn main() !void {
    const tree = try Node.init(std.heap.page_allocator, 10);
    defer tree.deinit(std.heap.page_allocator);

    try tree.insert(5);
    try tree.insert(7);
    try tree.insert(15);
    try tree.insert(20);

    tree.inorder();

    std.debug.print("\n", .{});

    const search = tree.search(12);

    if (search == null) {
        std.debug.print("search: null\n", .{});
        return;
    }

    std.debug.print("search: {d}\n", .{search.?.value});
}
